#import <Preferences/PSViewController.h>
#import "EZAddPhraseViewController.h"

@interface EZEditPhraseViewController : EZAddPhraseViewController
@property (nonatomic, retain) NSString *originalPhrase;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end
