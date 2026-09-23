#import "EZEditPhraseViewController.h"

@implementation EZEditPhraseViewController

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.originalPhrase = dict[@"phrase"];
        self.target = dict[@"phrase"];
        self.replacement = dict[@"replacement"];
        self.caseSensitive = dict[@"caseSensitive"] == nil ? YES : [dict[@"caseSensitive"] boolValue];
        self.wholeWord = [dict[@"wholeWord"] boolValue];
        self.scope = [dict[@"scope"] isKindOfClass:[NSString class]] ? dict[@"scope"] : @"all";
        self.selectedApplications = [dict[@"applications"] isKindOfClass:[NSArray class]] ? [dict[@"applications"] mutableCopy] : [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Edit Phrase";
}

- (void)savePhrase {
    if (self.target.length == 0 || self.replacement.length == 0 || [self.target isEqualToString:self.replacement]) return;
    [self.parent editPhrase:self.originalPhrase newPhrase:self.target replacement:self.replacement caseSensitive:self.caseSensitive wholeWord:self.wholeWord scope:self.scope applications:[self.selectedApplications copy]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addPhrase { [self savePhrase]; }
@end
