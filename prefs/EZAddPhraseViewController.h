#import <Preferences/PSViewController.h>
@class EZPhraseListViewController;

@interface EZAddPhraseViewController : PSViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, retain) NSString *target;
@property (nonatomic, retain) NSString *replacement;
@property (nonatomic, assign) BOOL caseSensitive;
@property (nonatomic, assign) BOOL wholeWord;
@property (nonatomic, retain) NSString *scope;
@property (nonatomic, retain) NSMutableArray *selectedApplications;
@property (nonatomic, assign) EZPhraseListViewController *parent;
@property (nonatomic, retain) UITableView *tableView;
@end
