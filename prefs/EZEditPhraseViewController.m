#import "EZEditPhraseViewController.h"
@implementation EZEditPhraseViewController
- (instancetype)initWithDictionary:(NSDictionary *)dict { self = [super init]; if (self) { self.originalPhrase = dict[@"phrase"]; self.target = dict[@"phrase"]; self.replacement = dict[@"replacement"]; self.caseSensitive = dict[@"caseSensitive"] == nil ? YES : [dict[@"caseSensitive"] boolValue]; self.wholeWord = [dict[@"wholeWord"] boolValue]; self.scope = dict[@"scope"] ?: @"all"; self.selectedApplications = [dict[@"applications"] mutableCopy] ?: [NSMutableArray array]; } return self; }
- (void)viewDidLoad { [super viewDidLoad]; self.title = @"Edit Phrase"; }
- (void)addPhrase { [self.parent editPhrase:self.originalPhrase newPhrase:self.target replacement:self.replacement caseSensitive:self.caseSensitive wholeWord:self.wholeWord scope:self.scope applications:self.selectedApplications]; [self.navigationController popViewControllerAnimated:YES]; }
@end
