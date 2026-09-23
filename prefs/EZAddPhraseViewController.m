#import "EZAddPhraseViewController.h"
#import "EZPhraseListViewController.h"
#import <Preferences/PSEditableTableCell.h>
#import <Preferences/PSSwitchTableCell.h>
#import "EZAppListViewController.h"

@interface PSEditableTableCell (Missing)
- (UITextField *)textField;
@end

@implementation EZAddPhraseViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.caseSensitive = YES;
        self.wholeWord = NO;
        self.scope = @"all";
        self.selectedApplications = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Add Phrase";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(savePhrase)];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self updateDoneButton];
}

- (void)savePhrase {
    if (self.target.length == 0 || self.replacement.length == 0 || [self.target isEqualToString:self.replacement]) return;
    [self.parent addPhrase:self.target replacement:self.replacement caseSensitive:self.caseSensitive wholeWord:self.wholeWord scope:self.scope applications:[self.selectedApplications copy]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addPhrase { [self savePhrase]; }

- (void)updateDoneButton {
    self.navigationItem.rightBarButtonItem.enabled = self.target.length > 0 && self.replacement.length > 0 && ![self.target isEqualToString:self.replacement];
}

- (void)setTarget:(NSString *)target { _target = [target copy]; [self updateDoneButton]; }
- (void)setReplacement:(NSString *)replacement { _replacement = [replacement copy]; [self updateDoneButton]; }
- (void)setTargetValue:(id)value forSpecifier:(PSSpecifier *)specifier { self.target = value; }
- (id)readTargetValue:(PSSpecifier *)specifier { return self.target; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 2 : 2; }
- (void)targetTextDidChange:(UITextField *)f { self.target = f.text; }
- (void)replacementTextDidChange:(UITextField *)f { self.replacement = f.text; }
- (void)caseSwitchDidChange:(UISwitch *)s { self.caseSensitive = s.on; }
- (void)wholeWordSwitchDidChange:(UISwitch *)s { self.wholeWord = s.on; }

- (NSString *)scopeTitle {
    if ([self.scope isEqualToString:@"selected"]) return [NSString stringWithFormat:@"Selected Apps (%lu)", (unsigned long)self.selectedApplications.count];
    if ([self.scope isEqualToString:@"excluded"]) return [NSString stringWithFormat:@"Except Selected Apps (%lu)", (unsigned long)self.selectedApplications.count];
    return @"All Apps";
}

- (void)chooseScope {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Application Scope" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *choices = @[
        @{ @"title": @"All Apps", @"scope": @"all" },
        @{ @"title": @"Selected Apps", @"scope": @"selected" },
        @{ @"title": @"All Apps Except Selected", @"scope": @"excluded" }
    ];
    for (NSDictionary *choice in choices) {
        [alert addAction:[UIAlertAction actionWithTitle:choice[@"title"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.scope = choice[@"scope"];
            [self.tableView reloadData];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)chooseApplications {
    EZAppListViewController *controller = [EZAppListViewController new];
    controller.parent = self;
    controller.selectedApplications = [self.selectedApplications mutableCopy];
    [self.navigationController pushViewController:controller animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        PSEditableTableCell *cell = [[PSEditableTableCell alloc] initWithStyle:1000 reuseIdentifier:@"EditTextCell"];
        cell.textLabel.tag = 317;
        cell.textLabel.text = indexPath.row == 0 ? @"Phrase" : @"Replacement";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textField.text = indexPath.row == 0 ? self.target : self.replacement;
        [cell.textField addTarget:self action:indexPath.row == 0 ? @selector(targetTextDidChange:) : @selector(replacementTextDidChange:) forControlEvents:UIControlEventEditingChanged];
        return cell;
    }
    if (indexPath.section == 1) {
        PSSwitchTableCell *cell = [[PSSwitchTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indexPath.row == 0 ? @"CaseSensitive" : @"WholeWord" specifier:nil];
        cell.textLabel.tag = 317;
        cell.textLabel.text = indexPath.row == 0 ? @"Case Sensitive" : @"Whole Word";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell setValue:@(indexPath.row == 0 ? self.caseSensitive : self.wholeWord)];
        [cell.control addTarget:self action:indexPath.row == 0 ? @selector(caseSwitchDidChange:) : @selector(wholeWordSwitchDidChange:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ScopeCell"];
    cell.textLabel.tag = 317;
    cell.textLabel.text = indexPath.row == 0 ? @"Application Scope" : @"Choose Apps";
    cell.detailTextLabel.text = indexPath.row == 0 ? [self scopeTitle] : @"";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        if (indexPath.row == 0) [self chooseScope];
        else [self chooseApplications];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
