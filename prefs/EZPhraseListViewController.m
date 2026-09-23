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

    _settings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath()];
    if (!_settings) _settings = [NSMutableDictionary dictionary];
    _settings[@"strings"] = [_settings[@"strings"] mutableCopy] ?: [NSMutableArray array];
    [self sortSettings];
}

- (void)updateSettings {
    [_settings writeToFile:settingsPath() atomically:YES];
    CFPreferencesSetAppValue(CFSTR("strings"), (__bridge CFPropertyListRef)[_settings[@"strings"] copy], CFSTR("xyz.skitty.ersatz"));
    CFPreferencesAppSynchronize(CFSTR("xyz.skitty.ersatz"));
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("xyz.skitty.ersatz.prefschanged"), NULL, NULL, true);
}

- (void)sortSettings {
    _strings = [NSMutableDictionary dictionary];
    _sortedStrings = [NSMutableDictionary dictionary];
    for (NSDictionary *rule in _settings[@"strings"]) {
        NSString *phrase = rule[@"phrase"];
        if (![phrase isKindOfClass:[NSString class]] || phrase.length == 0) continue;
        _strings[phrase] = rule[@"replacement"] ?: @"";
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
    if (!phrase.length || !replacement.length) return;
    if (!_settings[@"shownPrompt"]) _settings[@"shownPrompt"] = @YES;
    NSDictionary *rule = @{ @"phrase": phrase, @"replacement": replacement, @"caseSensitive": @(caseSensitive), @"wholeWord": @(wholeWord), @"scope": scope ?: @"all", @"applications": applications ?: @[] };
    [_settings[@"strings"] addObject:rule];
    [self updateSettings];
    [self sortSettings];
    [self.tableView reloadData];
}

- (void)editPhrase:(NSString *)oldPhrase newPhrase:(NSString *)phrase replacement:(NSString *)replacement caseSensitive:(BOOL)caseSensitive wholeWord:(BOOL)wholeWord scope:(NSString *)scope applications:(NSArray *)applications {
    if (!phrase.length || !replacement.length) return;
    NSMutableArray *rules = _settings[@"strings"];
    for (NSUInteger index = 0; index < rules.count; index++) {
        NSDictionary *oldRule = rules[index];
        if ([oldRule[@"phrase"] isEqualToString:oldPhrase]) {
            rules[index] = @{ @"phrase": phrase, @"replacement": replacement, @"caseSensitive": @(caseSensitive), @"wholeWord": @(wholeWord), @"scope": scope ?: @"all", @"applications": applications ?: @[] };
            [self updateSettings];
            [self sortSettings];
            [self.tableView reloadData];
            return;
        }
    }
}

- (NSArray *)sections { return [[_sortedStrings allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return [self sections].count; }
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
        if ([rule[@"phrase"] isEqualToString:phrase]) { [_settings[@"strings"] removeObject:rule]; break; }
    }
    [self updateSettings];
    [self sortSettings];
    [tableView reloadData];
}
@end
