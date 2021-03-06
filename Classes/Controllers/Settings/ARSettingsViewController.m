#import <Artsy+UIFonts/UIFont+ArtsyFonts.h>

#import "ARMailSettingsViewController.h"
#import "ARSupportSettingsViewController.h"
#import "ARSettingsViewController.h"
#import "Reachability+ConnectionExists.h"
#import "ARTableViewCell.h"
#import "ARFlatButton.h"
#import "ARToggleSwitch.h"
#import "NSString+TimeInterval.h"
#import "NSDate+Presentation.h"
#import "KVOController/FBKVOController.h"

typedef NS_ENUM(NSInteger, Sections) {
    SettingsNavigationSection,
    SyncingSection
};

typedef NS_ENUM(NSInteger, NavigationSettingsSectionRows) {
    EmailSettingsNavigationRow,
    AdminSettingsNavigationRow,
};

static const NSInteger kNumberOfSections = 2;
static const NSInteger kNumberOfRowsInSettingsSection = 2;
static const NSInteger kNumberOfRowsInSyncingSection = 1;
static const NSInteger kHeightOfTitleBar = 64;
static const NSInteger kHeightOfSettingsCell = 130;


@interface ARSettingsViewController ()
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) ARSyncStatusViewModel *syncStatusViewModel;
@property (nonatomic, strong) FBKVOController *kvoController;

@property (nonatomic, strong) IBOutlet UITableViewCell *syncViewCell;
@property (nonatomic, weak) IBOutlet UILabel *syncStatusLabel;
@property (nonatomic, weak) IBOutlet UILabel *syncStatusSubtitleLabel;

@property (nonatomic, weak) IBOutlet ARFlatButton *syncButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *syncActivityView;
@property (nonatomic, weak) IBOutlet UIImageView *syncNotificationImage;

@property (nonatomic, assign) BOOL isOffline;

@end


@implementation ARSettingsViewController

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    NSString *title = NSLocalizedString(@"Settings", @"Settings title");
    self.title = [title uppercaseString];

    self.kvoController = [FBKVOController controllerWithObserver:self];

    return self;
}

- (void)setSync:(ARSync *)sync
{
    self.syncStatusViewModel = _syncStatusViewModel ?: [[ARSyncStatusViewModel alloc] initWithSync:sync context:[CoreDataManager mainManagedObjectContext]];
}

#pragma mark -
#pragma mark view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateSyncUI];

    self.tableView.accessibilityLabel = @"Settings TableView";

    [self registerForNotifications];
    [self setupObservers];
}

- (void)viewDidUnload
{
    self.syncActivityView = nil;
    [super viewDidUnload];
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetSyncButton:)
                                                 name:ARNotEnoughDiskSpaceNotification
                                               object:nil];


    // we know ARAppDelegate started the notifier, so no need to do it here
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
}

- (void)setupObservers
{
    [self.kvoController observe:self.syncStatusViewModel keyPath:@"isSyncing" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        [self updateSyncUI];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    for (UITableViewCell *cell in self.tableView.visibleCells) {
        [cell setSelected:NO animated:NO];
    }

    [self updateSyncUI];
}

- (void)resetSyncButton:(NSNotification *)aNotification
{
    [self updateSyncUI];
    self.syncStatusLabel.text = @"";
}

- (void)reachabilityChanged:(NSNotification *)aNotification
{
    BOOL offline = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable;
    if (offline != self.isOffline) {
        _isOffline = offline;
        [self updateSyncUI];

        // Going from offline to online, it'll fix itself
        if (self.isOffline) {
            self.syncStatusLabel.text = @"Syncing paused: no Internet connection";
        }
    }
}

#pragma mark -
#pragma mark table view cell configuring

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == EmailSettingsNavigationRow) {
        cell.textLabel.text = @"Email Settings";

    } else if (indexPath.row == AdminSettingsNavigationRow) {
        cell.textLabel.text = @"Admin & Support";
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

#pragma mark -
#pragma mark table view delegate

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = SettingsCellReuse;
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];

    if (indexPath.section != SyncingSection) {
        if (cell == nil) {
            cell = [[ARTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        [self configureCell:cell forRowAtIndexPath:indexPath];
    }

    else {
        // We have the _syncViewCell in the nib.
        cell = self.syncViewCell;
        self.syncStatusLabel.font = [UIFont serifFontWithSize:ARFontSerif];
        self.syncStatusSubtitleLabel.font = [UIFont serifFontWithSize:ARFontSerifSmall];
        self.syncStatusSubtitleLabel.textColor = [UIColor artsyHeavyGrey];
    }

    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SyncingSection) return;

    if (indexPath.row == EmailSettingsNavigationRow) {
        ARMailSettingsViewController *mailVC = [[ARMailSettingsViewController alloc] init];
        [self.navigationController pushViewController:mailVC animated:YES];

    } else if (indexPath.row == AdminSettingsNavigationRow) {
        ARSupportSettingsViewController *adminSettingsVC = [[ARSupportSettingsViewController alloc] init];
        [self.navigationController pushViewController:adminSettingsVC animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SettingsNavigationSection:
            return kNumberOfRowsInSettingsSection;
        case SyncingSection:
            return kNumberOfRowsInSyncingSection;
    }

    return 0;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SyncingSection) {
        return CGRectGetHeight([self.syncViewCell frame]);
    }
    return ARTableViewCellSettingsHeight;
}

#pragma mark -
#pragma mark sync controller actions

- (IBAction)sync:(id)sender
{
    if (ARIsOSSBuild) {
        self.syncStatusLabel.text = @"Sync is disabled on OSS builds.";
        return;
    }

    [self.syncStatusViewModel startSync];
    [ARAnalytics event:ARManualSyncStartEvent];

    self.syncButton.enabled = NO;
    [self updateSyncUI];
}

#pragma mark -
#pragma mark UI setup

- (void)updateSyncUI
{
    self.syncStatusLabel.text = self.syncStatusViewModel.titleText;
    self.syncStatusSubtitleLabel.text = self.syncStatusViewModel.subtitleText;

    if (self.syncStatusViewModel.shouldShowSyncButton)
        [self configureSyncButton];
    else
        self.syncButton.alpha = 0;

    self.syncActivityView.alpha = self.syncStatusViewModel.syncActivityViewAlpha;

    switch (self.syncStatusViewModel.currentSyncImageNotification) {
        case ARSyncImageNotificationRecommendSync:
            [self setupCircleImageView];
            break;
        case ARSyncImageNotificationUpToDate:
            [self setupCheckImageView];
            break;
        case ARSyncImageNotificationNone:
            self.syncNotificationImage.alpha = 0;
            break;
    }
}

- (void)configureSyncButton
{
    [self.syncButton setTitle:self.syncStatusViewModel.syncButtonTitle forState:UIControlStateNormal];

    BOOL enableSyncButton = self.syncStatusViewModel.shouldEnableSyncButton;
    self.syncButton.alpha = enableSyncButton ? 1 : 0.5;
    self.syncButton.userInteractionEnabled = enableSyncButton;

    UIColor *buttonColor = self.syncStatusViewModel.syncButtonColor;
    self.syncButton.backgroundColor = buttonColor;
    self.syncButton.borderColor = buttonColor;
}

- (void)setupCheckImageView
{
    UIImage *check = [[UIImage imageNamed:@"check-active"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.syncNotificationImage.image = check;
    self.syncNotificationImage.tintColor = [UIColor artsyHighlightGreen];
    self.syncNotificationImage.backgroundColor = [UIColor clearColor];
    self.syncNotificationImage.alpha = 1;
}

- (void)setupCircleImageView
{
    self.syncNotificationImage.layer.cornerRadius = self.syncNotificationImage.frame.size.height / 2;
    self.syncNotificationImage.backgroundColor = [UIColor artsyPurple];
    self.syncNotificationImage.alpha = 1;
}

- (CGSize)preferredContentSize
{
    CGFloat contentHeight = kNumberOfRowsInSettingsSection * ARTableViewCellSettingsHeight;
    contentHeight += kHeightOfTitleBar;
    contentHeight += kHeightOfSettingsCell;
    return CGSizeMake(320, contentHeight);
}

- (NSUserDefaults *)defaults
{
    return _defaults ?: [NSUserDefaults standardUserDefaults];
}

@end
