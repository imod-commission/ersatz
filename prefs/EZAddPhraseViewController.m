#import "EZAddPhraseViewController.h"
#import <Preferences/PSEditableTableCell.h>
#import <Preferences/PSSwitchTableCell.h>
#import "EZAppListViewController.h"

@interface PSEditableTableCell (Missing)
- (UITextField *)textField;
@end

@implementation EZAddPhraseViewController
- (instancetype)init { self = [super init]; if (self) { self.caseSensitive = YES; self.scope = @"all"; self.selectedApplications = [NSMutableArray array]; } return self; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Add Phrase";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(addPhrase)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped]; self.tableView.delegate = self; self.tableView.dataSource = self; [self.view addSubview:self.tableView];
}
- (void)addPhrase { [self.parent addPhrase:self.target replacement:self.replacement caseSensitive:self.caseSensitive wholeWord:self.wholeWord scope:self.scope applications:self.selectedApplications]; [self.navigationController popViewControllerAnimated:YES]; }
- (void)updateDoneButton { self.navigationItem.rightBarButtonItem.enabled = self.target.length > 0 && self.replacement.length > 0 && ![self.target isEqualToString:self.replacement]; }
- (void)setTarget:(NSString *)target { _target = [target copy]; [self updateDoneButton]; }
- (void)setReplacement:(NSString *)replacement { _replacement = [replacement copy]; [self updateDoneButton]; }
- (void)setTargetValue:(id)value forSpecifier:(PSSpecifier *)specifier { self.target = value; }
- (id)readTargetValue:(PSSpecifier *)specifier { return self.target; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 2 : (section == 1 ? 2 : 2); }
- (void)targetTextDidChange:(UITextField *)f { self.target = f.text; }
- (void)replacementTextDidChange:(UITextField *)f { self.replacement = f.text; }
- (void)caseSwitchDidChange:(UISwitch *)s { self.caseSensitive = s.on; }
- (void)wholeWordSwitchDidChange:(UISwitch *)s { self.wholeWord = s.on; }
- (NSString *)scopeTitle { if ([self.scope isEqualToString:@"selected"]) return [NSString stringWithFormat:@"Selected Apps (%lu)", (unsigned long)self.selectedApplications.count]; if ([self.scope isEqualToString:@"excluded"]) return [NSString stringWithFormat:@"Excluded Apps (%lu)", (unsigned long)self.selectedApplications.count]; return @"All Apps"; }
- (void)chooseScope { UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Application Scope" message:nil preferredStyle:UIAlertControllerStyleActionSheet]; for (NSDictionary *choice in @[@{@"title": @"All Apps", @"scope": @"all"}, @{@"title": @"Selected Apps", @"scope": @"selected"}, @{@"title": @"All Apps Except Selected", @"scope": @"excluded"}]) [alert addAction:[UIAlertAction actionWithTitle:choice[@"title"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) { self.scope = choice[@"scope"]; [self.tableView reloadData]; }]]; [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:alert animated:YES completion:nil]; }
- (void)chooseApplications { EZAppListViewController *controller = [EZAppListViewController new]; controller.parent = self; controller.selectedApplications = [self.selectedApplications mutableCopy]; [self.navigationController pushViewController:controller animated:YES]; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) { PSEditableTableCell *c = [[PSEditableTableCell alloc] initWithStyle:1000 reuseIdentifier:@"EditTextCell"]; c.textLabel.tag = 317; c.textLabel.text = indexPath.row ? @"Replacement" : @"Phrase"; c.selectionStyle = UITableViewCellSelectionStyleNone; c.textField.text = indexPath.row ? self.replacement : self.target; [c.textField addTarget:self action:indexPath.row ? @selector(replacementTextDidChange:) : @selector(targetTextDidChange:) forControlEvents:UIControlEventEditingChanged]; return c; }
    if (indexPath.section == 1) { PSSwitchTableCell *c = [[PSSwitchTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indexPath.row ? @"WholeWord" : @"CaseSensitive" specifier:nil]; c.textLabel.tag = 317; c.textLabel.text = indexPath.row ? @"Whole Word" : @"Case Sensitive"; [c setValue:@(indexPath.row ? self.wholeWord : self.caseSensitive)]; [c.control addTarget:self action:indexPath.row ? @selector(wholeWordSwitchDidChange:) : @selector(caseSwitchDidChange:) forControlEvents:UIControlEventValueChanged]; return c; }
    UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ScopeCell"]; c.textLabel.tag = 317; c.textLabel.text = indexPath.row ? @"Choose Apps" : @"Application Scope"; c.detailTextLabel.text = indexPath.row ? @"" : [self scopeTitle]; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; return c;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { if (indexPath.section == 2) { if (indexPath.row == 0) [self chooseScope]; else [self chooseApplications]; } [tableView deselectRowAtIndexPath:indexPath animated:YES]; }
@end
