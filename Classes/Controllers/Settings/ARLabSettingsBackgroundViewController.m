#import "ARLabSettingsBackgroundViewController.h"
#import "AROptions.h"
#import "ARToggleSwitch.h"
#import "ARTableViewCell.h"
#import "ARTheme.h"
#import <Artsy+UIFonts/UIFont+ArtsyFonts.h>


@implementation ARLabSettingsBackgroundViewController

- (void)viewDidLoad
{
    [self.navigationController setNavigationBarHidden:[UIDevice isPad]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[ARTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"backgroundCell"];
    cell.textLabel.text = NSLocalizedString(@"White Background", @"Title for white Folio setting toggle");
    cell.textLabel.font = [UIFont serifFontWithSize:17];

    ARToggleSwitch *toggle = [ARToggleSwitch buttonWithFrame:CGRectMake(0, 0, 76, 28)];
    toggle.on = self.usingWhiteFolio;
    toggle.userInteractionEnabled = NO;

    cell.accessoryView = toggle;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL on = !self.usingWhiteFolio;
    [self setWhiteFolio:on];

    ARToggleSwitch *toggle = (id)[tableView cellForRowAtIndexPath:indexPath].accessoryView;
    toggle.on = on;

    [ARTheme setupWithWhiteFolio:on];

    [[NSNotificationCenter defaultCenter] postNotificationName:ARUserDidChangeGridFilteringSettingsNotification object:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (BOOL)usingWhiteFolio
{
    return [self.defaults boolForKey:AROptionsUseWhiteFolio];
}

- (void)setWhiteFolio:(BOOL)on
{
    [self.defaults setBool:on forKey:AROptionsUseWhiteFolio];
    [self.defaults synchronize];
}

- (NSUserDefaults *)defaults
{
    return _defaults ?: [NSUserDefaults standardUserDefaults];
}

@end
