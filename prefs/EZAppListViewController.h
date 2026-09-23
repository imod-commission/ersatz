#import <UIKit/UIKit.h>
@class EZAddPhraseViewController;

@interface EZAppListViewController : UITableViewController
@property (nonatomic, retain) NSArray *applications;
@property (nonatomic, retain) NSMutableArray *selectedApplications;
@property (nonatomic, retain) EZAddPhraseViewController *parent;
@end
