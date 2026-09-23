#import <CoreData/CoreData.h>
#import <rootless.h>
#import "EZPhraseListViewController.h"
#import "EZAddPhraseViewController.h"
#import "EZEditPhraseViewController.h"

static NSString *settingsPath = ROOT_PATH_NS(@"/var/mobile/Library/Preferences/xyz.skitty.ersatz.plist");

@implementation EZPhraseListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Ersatz";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPhrase)];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];

    CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("xyz.skitty.ersatz"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (keyList) {
        _settings = (NSMutableDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, CFSTR("xyz.skitty.ersatz"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
        CFRelease(keyList);
    } else {
        _settings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    }
    if (!_settings) _settings = [NSMutableDictionary dictionary];
    _settings[@"strings"] = [_settings[@"strings"] mutableCopy] ?: [NSMutableArray array];
    [self sortSettings];
}

- (void)updateSettings {
    CFPreferencesSetAppValue(CFSTR("strings"), (__bridge CFPropertyListRef)_settings[@"strings"], CFSTR("xyz.skitty.ersatz"));
    [_settings writeToFile:settingsPath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("xyz.skitty.ersatz.prefschanged"), NULL, NULL, true);
}

- (void)sortSettings {
    _strings = [NSMutableDictionary dictionary];
    _sortedStrings = [NSMutableDictionary dictionary];
    for (NSDictionary *rule in _settings[@"strings"]) {
        NSString *phrase = rule[@"phrase"];
        if (phrase.length == 0) continue;
        _strings[phrase] = rule[@"replacement"] ?: @"";
        NSString *section = [[phrase substringToIndex:1] uppercaseString];
        if (!_sortedStrings[section]) _sortedStrings[section] = [NSMutableArray array];
        [_sortedStrings[section] addObject:phrase];
    }
    for (NSString *section in _sortedStrings) [_sortedStrings[section] sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void)addPhrase {
    EZAddPhraseViewController *controller = [[EZAddPhraseViewController alloc] init];
    controller.parent = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)addPhrase:(NSString *)phrase replacement:(NSString *)replacement caseSensitive:(BOOL)caseSensitive wholeWord:(BOOL)wholeWord {
    if (!_settings[@"shownPrompt"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice" message:@"To apply this replacement system-wide, you may need to respring or reopen the app." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        _settings[@"shownPrompt"] = @YES;
    }
    [_settings[@"strings"] addObject:@{ @"phrase": phrase, @"replacement": replacement, @"caseSensitive": @(caseSensitive), @"wholeWord": @(wholeWord) }];
    [self updateSettings];
    [self sortSettings];
    [self.tableView reloadData];
}

- (void)editPhrase:(NSString *)phrase newPhrase:(NSString *)newPhrase replacement:(NSString *)replacement caseSensitive:(BOOL)caseSensitive wholeWord:(BOOL)wholeWord {
    for (NSInteger i = 0; i < [_settings[@"strings"] count]; i++) {
        NSDictionary *rule = _settings[@"strings"][i];
        if ([rule[@"phrase"] isEqualToString:phrase]) {
            _settings[@"strings"][i] = @{ @"phrase": newPhrase, @"replacement": replacement, @"caseSensitive": @(caseSensitive), @"wholeWord": @(wholeWord) };
            break;
        }
    }
    [self updateSettings];
    [self sortSettings];
    [self.tableView reloadData];
}

- (NSArray *)sortedSections { return [[_sortedStrings allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return _sortedStrings.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [_sortedStrings[[self sortedSections][section]] count]; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return [self sortedSections][section]; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    NSString *phrase = _sortedStrings[[self sortedSections][indexPath.section]][indexPath.row];
    cell.textLabel.tag = 317;
    cell.detailTextLabel.tag = 317;
    cell.textLabel.text = phrase;
    cell.detailTextLabel.text = _strings[phrase];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *phrase = _sortedStrings[[self sortedSections][indexPath.section]][indexPath.row];
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
    NSString *phrase = _sortedStrings[[self sortedSections][indexPath.section]][indexPath.row];
    for (NSDictionary *rule in [_settings[@"strings"] copy]) {
        if ([rule[@"phrase"] isEqualToString:phrase]) { [_settings[@"strings"] removeObject:rule]; break; }
    }
    [self updateSettings];
    [self sortSettings];
    [tableView reloadData];
}
@end
