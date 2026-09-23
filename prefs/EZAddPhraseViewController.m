#import "EZAddPhraseViewController.h"
#import <Preferences/PSEditableTableCell.h>
#import <Preferences/PSSwitchTableCell.h>

@interface PSEditableTableCell (Missing)
- (UITextField *)textField;
@end

@implementation EZAddPhraseViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.caseSensitive = YES;
        self.wholeWord = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Add Phrase";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(addPhrase)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)addPhrase {
    [self.parent addPhrase:self.target replacement:self.replacement caseSensitive:self.caseSensitive wholeWord:self.wholeWord];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateDoneButton {
    BOOL valid = self.target.length > 0 && self.replacement.length > 0 && ![self.target isEqualToString:self.replacement];
    self.navigationItem.rightBarButtonItem.enabled = valid;
}

- (void)setTarget:(NSString *)target { _target = [target copy]; [self updateDoneButton]; }
- (void)setReplacement:(NSString *)replacement { _replacement = [replacement copy]; [self updateDoneButton]; }
- (void)setTargetValue:(id)value forSpecifier:(PSSpecifier *)specifier { self.target = value; }
- (id)readTargetValue:(PSSpecifier *)specifier { return self.target; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 2 : 2; }
- (void)targetTextDidChange:(UITextField *)field { self.target = field.text; }
- (void)replacementTextDidChange:(UITextField *)field { self.replacement = field.text; }
- (void)caseSwitchDidChange:(UISwitch *)control { self.caseSensitive = control.on; }
- (void)wholeWordSwitchDidChange:(UISwitch *)control { self.wholeWord = control.on; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        PSEditableTableCell *cell = [[PSEditableTableCell alloc] initWithStyle:1000 reuseIdentifier:@"EditTextCell"];
        cell.textLabel.tag = 317;
        cell.textLabel.text = indexPath.row == 0 ? @"Phrase" : @"Replacement";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textField.text = indexPath.row == 0 ? self.target : self.replacement;
        [cell.textField addTarget:self action:indexPath.row == 0 ? @selector(targetTextDidChange:) : @selector(replacementTextDidChange:) forControlEvents:UIControlEventEditingChanged];
        if (indexPath.row == 1) cell.textField.returnKeyType = UIReturnKeyDone;
        return cell;
    }

    PSSwitchTableCell *cell = [[PSSwitchTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indexPath.row == 0 ? @"CaseSwitchCell" : @"WholeWordSwitchCell" specifier:nil];
    cell.textLabel.tag = 317;
    cell.textLabel.text = indexPath.row == 0 ? @"Case Sensitive" : @"Whole Word";
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell setValue:@(indexPath.row == 0 ? self.caseSensitive : self.wholeWord)];
    [cell.control addTarget:self action:indexPath.row == 0 ? @selector(caseSwitchDidChange:) : @selector(wholeWordSwitchDidChange:) forControlEvents:UIControlEventValueChanged];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { [tableView deselectRowAtIndexPath:indexPath animated:YES]; }
@end
