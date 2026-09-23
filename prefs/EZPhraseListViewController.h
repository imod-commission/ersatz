#import <Preferences/PSViewController.h>
@interface EZPhraseListViewController : PSViewController <UITableViewDataSource, UITableViewDelegate> { NSMutableDictionary *_settings; NSMutableDictionary *_strings; NSMutableDictionary<NSString *, NSMutableArray *> *_sortedStrings; }
@property (nonatomic, retain) UITableView *tableView;
- (void)addPhrase:(NSString *)phrase replacement:(NSString *)replacement caseSensitive:(BOOL)caseSensitive wholeWord:(BOOL)wholeWord scope:(NSString *)scope applications:(NSArray *)applications;
- (void)editPhrase:(NSString *)phrase newPhrase:(NSString *)newPhrase replacement:(NSString *)replacement caseSensitive:(BOOL)caseSensitive wholeWord:(BOOL)wholeWord scope:(NSString *)scope applications:(NSArray *)applications;
@end
