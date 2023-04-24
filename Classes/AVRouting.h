//
//  AVRouting.h
//  Tranquil
//
//  Created by Dana Buehre on 4/8/22.
//

#import <UIKit/UIKit.h>

@interface MRAVOutputDevice : NSObject
@end

@interface SFShareAudioViewController : UINavigationController
@property (nonatomic, copy) void (^completion)(void);
+ (SFShareAudioViewController *)instantiateViewController;
@end

@interface MPAVRoute : NSObject
@property (nonatomic,copy) NSString * routeName;
@property (assign,getter=isPicked,nonatomic) BOOL picked;
@property (nonatomic,readonly) NSString * routeUID;
@property (nonatomic, readonly, getter=isShareableRoute) BOOL shareableRoute;
@end

@interface MPAVEndpointRoute : MPAVRoute
+ (void)getActiveEndpointRouteWithCompletion:(id)completion ;
@end

@interface MPAVRoutingViewItem : NSObject
@property (nonatomic, readonly) NSInteger type;
@property (nonatomic, readonly) NSArray *routes;
@property (nonatomic, readonly) MPAVRoute *mainRoute;
@property (nonatomic, readonly) MPAVRoute *route;
- (MPAVRoute *)mainRoute;
@end

@interface MPAVRoutingController : NSObject
- (BOOL)pickRoute:(MPAVRoute *)route;
+ (void)getActiveRouteWithCompletion:(void (^)(MPAVRoute *route))completion;
+ (void)setActiveRoute:(MPAVRoute *)route completion:(id)completion;
@end

@protocol MPAVRoutingTableViewCellDelegate <NSObject>

@optional
-(void)routingCell:(id)arg1 mirroringSwitchValueDidChange:(BOOL)arg2;
-(void)routingCellDidTapToExpand:(id)arg1;
@end

@protocol MPAVRoutingViewControllerThemeDelegate <NSObject>

@optional
- (void)routingViewController:(id)routingViewController willDisplayCell:(id)cell;
- (void)routingViewController:(id)routingViewController willDisplayHeaderView:(id)header;
- (UIEdgeInsets*)contentInsetsForRoutingViewController:(id)routingViewController;
@end

@protocol MPAVRoutingViewControllerDelegate <NSObject>

@optional
- (void)routingViewController:(id)routingViewController didPickRoute:(MPAVRoute *)route;
- (void)routingViewControllerDidUpdateContents:(id)arg1;
- (void)routingViewController:(id)routingViewController didSelectRoutingViewItem:(MPAVRoutingViewItem *)routingViewItem;
@end

@protocol MPAVRoutingControllerDelegate <NSObject>

@optional
- (void)routingControllerAvailableRoutesDidChange:(id)arg1;
- (void)routingController:(MPAVRoutingController *)routingController pickedRouteDidChange:(MRAVOutputDevice *)outputDevice;
- (void)routingController:(MPAVRoutingController *)routingController didFailToPickRouteWithError:(id)error;
- (void)routingController:(MPAVRoutingController *)routingController pickedRoutesDidChange:(id)arg2;
- (void)routingControllerExternalScreenTypeDidChange:(id)arg1;
- (void)routingControllerDidPauseFromActiveRouteChange:(id)arg1;
@end

@interface MPAVClippingTableViewCell : UITableViewCell
- (void)_setShouldHaveFullLengthBottomSeparator:(BOOL)fullLength;
- (void)_setShouldHaveFullLengthTopSeparator:(BOOL)fullLength;
@end

@interface MPAVRoutingTableViewCell : MPAVClippingTableViewCell

@property (nonatomic, assign, getter=isPendingSelection) BOOL pendingSelection;
@property (nonatomic, assign) BOOL isDisplayedAsPicked;

- (UIView *)separatorView;
- (UILabel *)subtitleView;
- (UILabel *)titleView;
@end

@interface MPAVRoutingViewController : UIViewController {

    NSArray* _cachedPendingPickedRoutes;
}
@property (nonatomic, readonly) MPAVRoutingController *_routingController; 
@property (nonatomic, weak) id<MPAVRoutingViewControllerDelegate> delegate;
@property (nonatomic, weak) id<MPAVRoutingViewControllerThemeDelegate> themeDelegate;
@property (nonatomic, copy) NSNumber * discoveryModeOverride;
@property (nonatomic, assign) NSUInteger mirroringStyle;
@property (nonatomic, assign) NSUInteger iconStyle;
@property (nonatomic, readonly) NSUInteger style;

@property (assign,setter=_setShouldAutomaticallyUpdateRoutesList:,nonatomic) BOOL _shouldAutomaticallyUpdateRoutesList;
@property (nonatomic, assign, setter=_setShouldPickRouteOnSelection:) BOOL _shouldPickRouteOnSelection;

@property (nonatomic,retain) MPAVEndpointRoute * endpointRoute;

@property (nonatomic, readonly) UITableView *_tableView;

- (instancetype)initWithStyle:(NSUInteger)style;

- (void)enqueueRefreshUpdate;
- (void)_setupUpdateTimerIfNecessary;
- (void)_beginRouteDiscovery;
- (void)_endRouteDiscovery;
- (void)_updateDisplayedRoutes;
- (void)_setNeedsDisplayedRoutesUpdate;
- (void)resetDisplayedRoutes;

- (void)routingController:(MPAVRoutingController *)routingController didFailToPickRouteWithError:(NSError *)error;
- (void)routingController:(MPAVRoutingController *)routingController pickedRoutesDidChange:(NSArray <MRAVOutputDevice *> *)outputDevices;
- (void)_configureCell:(MPAVRoutingTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;

@end
