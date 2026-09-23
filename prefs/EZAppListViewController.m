#import "EZAppListViewController.h"
#import "EZAddPhraseViewController.h"

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (NSArray *)allApplications;
@end

@implementation EZAppListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Select Apps";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    NSArray *all = workspaceClass ? [[workspaceClass defaultWorkspace] allApplications] : @[];
    NSMutableArray *apps = [NSMutableArray array];
    for (id app in all) {
        NSString *identifier = [app valueForKey:@"applicationIdentifier"];
        NSString *name = [app valueForKey:@"localizedName"] ?: [app valueForKey:@"itemName"];
        if (identifier.length && name.length) [apps addObject:@{ @"id": identifier, @"name": name }];
    }
    [apps sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
    self.applications = apps;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.applications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"AppCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    NSDictionary *app = self.applications[indexPath.row];
    cell.textLabel.text = app[@"name"];
    cell.detailTextLabel.text = app[@"id"];
    cell.accessoryType = [self.selectedApplications containsObject:app[@"id"]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = self.applications[indexPath.row][@"id"];
    if ([self.selectedApplications containsObject:identifier]) [self.selectedApplications removeObject:identifier];
    else [self.selectedApplications addObject:identifier];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)done {
    self.parent.selectedApplications = [self.selectedApplications mutableCopy];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
