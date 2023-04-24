//
//  TranquilRoutingViewController.m
//  Tranquil
//
//  Created by Dana Buehre on 4/8/22.
//

#import "TranquilRoutingViewController.h"
#import "Material.h"
#import "Prefix.h"

@interface TranquilRoutingViewController () <MPAVRoutingViewControllerDelegate, MPAVRoutingViewControllerThemeDelegate>
@property (nonatomic, strong) SFShareAudioViewController *shareAudioViewController;
@end

@implementation TranquilRoutingViewController

- (instancetype)init
{
    return [self initWithStyle:3];
}

- (instancetype)initWithStyle:(NSUInteger)style
{
    if (self = [super initWithStyle:style]) {
        
        [self setDelegate:self];
        [self setThemeDelegate:self];
        
        [self setIconStyle:1];
        [self setMirroringStyle:2];
        [self setDiscoveryModeOverride:@3];
        [self _setShouldPickRouteOnSelection:YES];
        [self _setShouldAutomaticallyUpdateRoutesList:YES];
    }
    
    return self;
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self refreshRoutes];

    [self _setNeedsDisplayedRoutesUpdate];
    [self _setupUpdateTimerIfNecessary];
    [self _beginRouteDiscovery];

    [MPAVEndpointRoute getActiveEndpointRouteWithCompletion:^(MPAVEndpointRoute *endpoint) {
        [self setEndpointRoute:endpoint];
    }];

//    if ([self respondsToSelector:@selector(enqueueRefreshUpdate)]) {
//
//        [self enqueueRefreshUpdate];
//    }
//
//    if ([self respondsToSelector:@selector(_updateDisplayedRoutes)]) {
//
//        [self _updateDisplayedRoutes];
//    }
    
    Log("");
}

- (void)setEndpointRoute:(MPAVEndpointRoute *)endpointRoute {
    [super setEndpointRoute:endpointRoute];
    [self refreshRoutes];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self _endRouteDiscovery];

    if (_shareAudioViewController && _shareAudioViewController.completion) {
        _shareAudioViewController.completion();
    }
    Log("");
}

- (void)_configureCell:(MPAVRoutingTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    [super _configureCell:cell forIndexPath:indexPath];

    BOOL picked = [self.endpointRoute.routeName isEqualToString:cell.titleView.text];
    [cell setPendingSelection:NO];
    [cell setIsDisplayedAsPicked:picked];
    Log("Cell: %@ Picked: %s", [NSString stringWithString: cell.titleView.text], picked ? "true" : "false");
}

#pragma mark - TranquilRoutingViewController

- (void)_applyCustomCellStyle:(UITableViewCell *)cell
{
    if ([cell isKindOfClass:NSClassFromString(@"MPAVRoutingTableViewCell")]) {
        MPAVRoutingTableViewCell *_cell = (MPAVRoutingTableViewCell *)cell;
        [_cell.separatorView.layer setOpacity:0.5];
        [_cell _setShouldHaveFullLengthTopSeparator:NO];
        [_cell _setShouldHaveFullLengthBottomSeparator:NO];
        [_cell.subtitleView setTextColor:_cell.titleView.textColor];
    }
}

- (void)_showAudioSharingController
{
    _shareAudioViewController = [NSClassFromString(@"SFShareAudioViewController") instantiateViewController];
    __weak typeof(self) weakSelf = self;
    _shareAudioViewController.completion = ^{
        [UIView transitionWithView:weakSelf.parentController.view duration:0.333 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [weakSelf.shareAudioViewController.view removeFromSuperview];
        } completion:^(BOOL finished) {
            weakSelf.shareAudioViewController = nil;
        }];
    };
    
    [_shareAudioViewController.view setFrame:self.parentController.view.bounds];
    [self.parentController addChildViewController:_shareAudioViewController];
    [_shareAudioViewController didMoveToParentViewController:self.parentController];
    
    CGFloat cornerRadius = self.parentController.view.subviews.firstObject.layer.cornerRadius ? : 38;
    MTMaterialView *materialBackground = ControlCenterForegroundMaterial();
    [materialBackground setFrame:_shareAudioViewController.view.bounds];
    SetCornerRadiusLayer(materialBackground.layer, cornerRadius);
    [_shareAudioViewController.view insertSubview:materialBackground atIndex:0];
    
    [_shareAudioViewController beginAppearanceTransition:YES animated:YES];
    [UIView transitionWithView:_parentController.view duration:0.333 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [self.parentController.view addSubview:self.shareAudioViewController.view];
    } completion:^(BOOL finished) {
        [self.shareAudioViewController endAppearanceTransition];
    }];
}

- (void)refreshRoutes {
    if ([self respondsToSelector:@selector(resetDisplayedRoutes)]) {
        [self resetDisplayedRoutes];
        [self _updateDisplayedRoutes];
    }
}

#pragma mark - MPAVRoutingViewControllerThemeDelegate

- (void)routingViewController:(id)routingViewController willDisplayCell:(id)cell
{
    [self _applyCustomCellStyle:cell];
}

- (void)routingViewController:(id)routingViewController willDisplayHeaderView:(id)header
{
    [(UIView *)header setBackgroundColor:UIColor.clearColor];
    Log("%@", header);
}

#pragma mark - MPAVRoutingViewControllerDelegate

- (void)routingViewController:(id)routingViewController didPickRoute:(MPAVRoute *)route
{
    Log("%@", route.debugDescription);
}

- (void)routingViewController:(id)routingViewController didSelectRoutingViewItem:(MPAVRoutingViewItem *)routingViewItem
{
    Log("%@", routingViewItem.debugDescription);

    if (!routingViewItem) return;

    if (routingViewItem.type != 2) {

        MPAVRoute *route;
        if ([routingViewItem respondsToSelector:@selector(mainRoute)]) {

            route = routingViewItem.mainRoute;
        }
        else if ([routingViewItem respondsToSelector:@selector(route)]) {

            route = routingViewItem.route;
        }

        if (route) {

            [self._routingController pickRoute:route];
        }
    }
    else {

        [self _showAudioSharingController];
    }
}

#pragma mark - MPAVRoutingControllerDelegate

- (void)routingController:(MPAVRoutingController *)routingController pickedRoutesDidChange:(NSArray <MRAVOutputDevice *> *)outputDevices
{
    [super routingController:routingController pickedRoutesDidChange:outputDevices];

    Log("routes %@", outputDevices);

    [MPAVEndpointRoute getActiveEndpointRouteWithCompletion:^(MPAVEndpointRoute *endpoint) {
        [self setEndpointRoute:endpoint];
    }];
}

@end
