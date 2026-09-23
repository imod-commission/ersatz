#import <UIKit/UIKit.h>
#import <rootless.h>
#import "EZPhraseListViewController.h"
#import "EZAddPhraseViewController.h"
#import "EZEditPhraseViewController.h"

static NSString *settingsPath(void) {
    return ROOT_PATH_NS(@"/var/mobile/Library/Preferences/xyz.skitty.ersatz.plist");
}

@implementation EZPhraseListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Ersatz";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddPhrase)];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];

    // Read the same plist path used by the tweak first. This keeps the UI and
    // injected processes on one source of truth, including rootless devices.
    _settings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath()];

    // Fall back to CFPreferences when the plist has not been created yet.
    if (!_settings) {
        CFPreferencesSynchronize(CFSTR("xyz.skitty.ersatz"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFArrayRef keys = CFPreferencesCopyKeyList(CFSTR("xyz.skitty.ersatz"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if (keys) {
            _settings = (NSMutableDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keys, CFSTR("xyz.skitty.ersatz"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
            CFRelease(keys);
        }
    }

    if (!_settings) _settings = [NSMutableDictionary dictionary];
    _settings[@"strings"] = [_settings[@"strings"] mutableCopy] ?: [NSMutableArray array];
    [self sortSettings];
}

- (void)updateSettings {
    NSArray *rules = [_settings[@"strings"] copy] ?: @[];
    NSString *path = settingsPath();

    // Write the complete dictionary directly, rather than only the strings
    // key. This also persists shownPrompt and works reliably with rootless.
    BOOL wroteFile = [_settings writeToFile:path atomically:YES];
    if (!wroteFile) {
        NSLog(@"[Ersatz] Could not write preferences to %@", path);
    }

    CFPreferencesSetAppValue(CFSTR("strings"), (__bridge CFPropertyListRef)rules, CFSTR("xyz.skitty.ersatz"));
    CFPreferencesAppSynchronize(CFSTR("xyz.skitty.ersatz"));
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("xyz.skitty.ersatz.prefschanged"), NULL, NULL, true);
}

- (void)sortSettings {
    _strings = [NSMutableDictionary dictionary];
    _sortedStrings = [NSMutableDictionary dictionary];
    for (NSDictionary *rule in _settings[@"strings"]) {
        NSString *phrase = rule[@"phrase"];
        if (![phrase isKindOfClass:[NSString class]] || phrase.length == 0) continue;
        _strings[phrase] = [rule[@"replacement"] isKindOfClass:[NSString class]] ? rule[@"replacement"] : @"";
        NSString *section = [[phrase substringToIndex:1] uppercaseString];
        if (!_sortedStrings[section]) _sortedStrings[section] = [NSMutableArray array];
        [_sortedStrings[section] addObject:phrase];
    }
    for (NSString *section in _sortedStrings) [_sortedStrings[section] sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void)showAddPhrase {
    EZAddPhraseViewController *controller = [EZAddPhraseViewController new];
    controller.parent = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)addPhrase:(NSString *)phrase replacement:(NSString *)replacement caseSensitive:(BOOL)caseSensitive wholeWord:(BOOL)wholeWord scope:(NSString *)scope applications:(NSArray *)applications {
    if (!_settings[@"shownPrompt"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice" message:@"Changes may require reopening apps or respringing." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        _settings[@"shownPrompt"] = @YES;
    }
    NSDictionary *rule = @{ @"phrase": phrase ?: @"", @"replacement": replacement ?: @"", @"caseSensitive": @(caseSensitive), @"wholeWord": @(wholeWord), @"scope": scope ?: @"all", @"applications": applications ?: @[] };
    [_settings[@"strings"] addObject:rule];
    [self updateSettings];
    [self sortSettings];
    [self.tableView reloadData];
}

- (void)editPhrase:(NSString *)oldPhrase newPhrase:(NSString *)phrase replacement:(NSString *)replacement caseSensitive:(BOOL)caseSensitive wholeWord:(BOOL)wholeWord scope:(NSString *)scope applications:(NSArray *)applications {
    for (NSUInteger i = 0; i < [_settings[@"strings"] count]; i++) {
        NSDictionary *rule = _settings[@"strings"][i];
        if ([rule[@"phrase"] isEqualToString:oldPhrase]) {
            _settings[@"strings"][i] = @{ @"phrase": phrase ?: @"", @"replacement": replacement ?: @"", @"caseSensitive": @(caseSensitive), @"wholeWord": @(wholeWord), @"scope": scope ?: @"all", @"applications": applications ?: @[] };
            break;
        }
    }
    [self updateSettings];
    [self sortSettings];
    [self.tableView reloadData];
}

- (NSArray *)sections { return [[_sortedStrings allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return _sortedStrings.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [_sortedStrings[[self sections][section]] count]; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return [self sections][section]; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
    NSString *phrase = _sortedStrings[[self sections][indexPath.section]][indexPath.row];
    cell.textLabel.tag = 317;
    cell.detailTextLabel.tag = 317;
    cell.textLabel.text = phrase;
    cell.detailTextLabel.text = _strings[phrase];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *phrase = _sortedStrings[[self sections][indexPath.section]][indexPath.row];
    for (NSDictionary *rule in _settings[@"strings"]) {
        if ([rule[@"phrase"] isEqualToString:phrase]) {
            EZEditPhraseViewController *controller = [[EZEditPhraseViewController alloc] initWithDictionary:rule];
            controller.parent = self;
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    NSString *phrase = _sortedStrings[[self sections][indexPath.section]][indexPath.row];
    for (NSDictionary *rule in [_settings[@"strings"] copy]) {
        if ([rule[@"phrase"] isEqualToString:phrase]) {
            [_settings[@"strings"] removeObject:rule];
            break;
        }
    }
    [self updateSettings];
    [self sortSettings];
    [tableView reloadData];
}
@end
