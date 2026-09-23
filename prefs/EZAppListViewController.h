#import <UIKit/UIKit.h>
@class EZPhraseListViewController;

@interface EZAppListViewController : UITableViewController
@property (nonatomic, retain) NSArray *applications;
@property (nonatomic, retain) NSMutableArray *selectedApplications;
@property (nonatomic, retain) EZPhraseListViewController *parent;
@end
