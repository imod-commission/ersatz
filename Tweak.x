#import <UIKit/UIKit.h>
#import <rootless.h>

static NSString *bundleIdentifier = @"xyz.skitty.ersatz";
static NSString *settingsPath = ROOT_PATH_NS(@"/var/mobile/Library/Preferences/");
static NSMutableDictionary *keyedSettings;
static NSDictionary<NSString *, NSString *> *strings;

static NSString *currentApplicationIdentifier(void) {
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    if (identifier.length == 0) identifier = [[NSBundle bundleForClass:[UIApplication class]] bundleIdentifier];
    return identifier;
}

static void refreshPrefs(void) {
    CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    NSMutableDictionary *settings = nil;
    if (keyList) {
        settings = (NSMutableDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
        CFRelease(keyList);
    }
    if (!settings) settings = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@%@.plist", settingsPath, bundleIdentifier]];
    if (!settings) settings = [NSMutableDictionary dictionary];

    keyedSettings = [NSMutableDictionary dictionary];
    NSMutableDictionary *replacementMap = [NSMutableDictionary dictionary];
    for (NSDictionary *rule in settings[@"strings"]) {
        NSString *phrase = rule[@"phrase"];
        if (![phrase isKindOfClass:[NSString class]] || phrase.length == 0) continue;
        replacementMap[phrase] = [rule[@"replacement"] isKindOfClass:[NSString class]] ? rule[@"replacement"] : @"";
        keyedSettings[phrase] = rule;
    }
    strings = [replacementMap copy];
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    refreshPrefs();
}

static BOOL ruleAppliesToCurrentApplication(NSDictionary *rule) {
    NSString *scope = rule[@"scope"];
    if (![scope isKindOfClass:[NSString class]] || [scope isEqualToString:@"all"]) return YES;

    NSArray *applications = rule[@"applications"];
    if (![applications isKindOfClass:[NSArray class]]) return NO;
    NSString *identifier = currentApplicationIdentifier();
    BOOL selected = identifier.length > 0 && [applications containsObject:identifier];

    if ([scope isEqualToString:@"selected"]) return selected;
    if ([scope isEqualToString:@"excluded"]) return !selected;
    return YES;
}

static BOOL ruleCaseSensitive(NSDictionary *rule) {
    return rule[@"caseSensitive"] == nil ? YES : [rule[@"caseSensitive"] boolValue];
}

static NSArray<NSValue *> *replacementRanges(NSString *text, NSString *find, NSDictionary *rule) {
    if (text.length == 0 || find.length == 0) return @[];
    if (![rule[@"wholeWord"] boolValue]) {
        NSMutableArray *ranges = [NSMutableArray array];
        NSStringCompareOptions options = ruleCaseSensitive(rule) ? 0 : NSCaseInsensitiveSearch;
        NSRange searchRange = NSMakeRange(0, text.length);
        while (searchRange.length > 0) {
            NSRange range = [text rangeOfString:find options:options range:searchRange];
            if (range.location == NSNotFound) break;
            [ranges addObject:[NSValue valueWithRange:range]];
            NSUInteger next = NSMaxRange(range);
            if (next >= text.length) break;
            searchRange = NSMakeRange(next, text.length - next);
        }
        return ranges;
    }

    NSString *pattern = [NSString stringWithFormat:@"(?<![\\p{L}\\p{N}_])%@(?!(?:[\\p{L}\\p{N}_]))", [NSRegularExpression escapedPatternForString:find]];
    NSRegularExpressionOptions options = ruleCaseSensitive(rule) ? 0 : NSRegularExpressionCaseInsensitive;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:nil];
    return regex ? [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)] : @[];
}

static NSString *replaceString(NSString *text, NSString *find, NSString *replacement, NSDictionary *rule) {
    if (!text || !find || !replacement) return text;
    NSMutableString *result = [text mutableCopy];
    NSArray<NSValue *> *ranges = replacementRanges(text, find, rule);
    for (NSInteger i = ranges.count - 1; i >= 0; i--) [result replaceCharactersInRange:[ranges[i] rangeValue] withString:replacement];
    return result;
}

static NSAttributedString *replaceAttributedString(NSAttributedString *text, NSString *find, NSString *replacement, NSDictionary *rule) {
    if (!text || !find || !replacement) return text;
    NSMutableAttributedString *result = [text mutableCopy];
    NSArray<NSValue *> *ranges = replacementRanges(result.string, find, rule);
    for (NSInteger i = ranges.count - 1; i >= 0; i--) {
        NSRange range = [ranges[i] rangeValue];
        NSDictionary *attributes = [result attributesAtIndex:range.location effectiveRange:nil];
        NSAttributedString *replacementString = [[NSAttributedString alloc] initWithString:replacement attributes:attributes];
        [result replaceCharactersInRange:range withAttributedString:replacementString];
    }
    return [result copy];
}

static NSString *applyRules(NSString *text) {
    for (NSString *find in strings) {
        NSDictionary *rule = keyedSettings[find];
        if (ruleAppliesToCurrentApplication(rule)) text = replaceString(text, find, strings[find], rule);
    }
    return text;
}

static NSAttributedString *applyAttributedRules(NSAttributedString *text) {
    for (NSString *find in strings) {
        NSDictionary *rule = keyedSettings[find];
        if (ruleAppliesToCurrentApplication(rule)) text = replaceAttributedString(text, find, strings[find], rule);
    }
    return text;
}

%hook UILabel
- (void)setText:(NSString *)text { %orig(self.tag == 317 ? text : applyRules(text)); }
- (void)setAttributedText:(NSAttributedString *)text { %orig(self.tag == 317 ? text : applyAttributedRules(text)); }
%end

%hook UITextView
- (void)setText:(NSString *)text { %orig(applyRules(text)); }
- (void)setAttributedText:(NSAttributedString *)text { %orig(applyAttributedRules(text)); }
%end

%hook SBApplication
- (void)setDisplayName:(id)text { %orig([text isKindOfClass:[NSString class]] ? applyRules(text) : text); }
- (id)displayName { id text = %orig; return [text isKindOfClass:[NSString class]] ? applyRules(text) : text; }
%end

%hook SBFolder
- (void)setDisplayName:(id)text { %orig([text isKindOfClass:[NSString class]] ? applyRules(text) : text); }
- (id)displayName { id text = %orig; return [text isKindOfClass:[NSString class]] ? applyRules(text) : text; }
%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)PreferencesChangedCallback, CFSTR("xyz.skitty.ersatz.prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    refreshPrefs();
}
