#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FloatingButton.h"
#import "SettingsUI.h"
#import "ArrowOverlay.h"
#import "EngineBridge.h"

static UIWindow *gOverlayWindow = nil;
static FloatingButton *gFloatingButton = nil;
static ArrowOverlay *gArrowOverlay = nil;
static BOOL gEnabled = YES;

@interface PassThroughWindow : UIWindow
@end

@implementation PassThroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    // Pass through if we hit the window or the clear root view
    if (hit == self || hit == self.rootViewController.view) return nil;
    return hit;
}
@end

@interface PassThroughView : UIView
@end

@implementation PassThroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) return nil;
    return hit;
}
@end

@interface LichessAssistantLoader : NSObject
@end

@implementation LichessAssistantLoader

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupOverlay];
    });
}

+ (void)setupOverlay {
    if (gOverlayWindow) return;

    gOverlayWindow = [[PassThroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    gOverlayWindow.windowLevel = UIWindowLevelAlert + 1;
    gOverlayWindow.backgroundColor = [UIColor clearColor];
    gOverlayWindow.hidden = NO;

    UIViewController *root = [UIViewController new];
    PassThroughView *rootView = [[PassThroughView alloc] initWithFrame:gOverlayWindow.bounds];
    rootView.backgroundColor = [UIColor clearColor];
    root.view = rootView;
    gOverlayWindow.rootViewController = root;

    gArrowOverlay = [[ArrowOverlay alloc] initWithFrame:root.view.bounds];
    gArrowOverlay.userInteractionEnabled = NO;
    [root.view addSubview:gArrowOverlay];

    gFloatingButton = [[FloatingButton alloc] initWithFrame:CGRectMake(20, 120, 56, 56)];
    [gFloatingButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    [root.view addSubview:gFloatingButton];

    [EngineBridge shared];
    [SettingsUI shared].onSettingsChanged = ^{ [self refresh]; };
}

+ (void)buttonTapped {
    [[SettingsUI shared] presentFrom:gOverlayWindow.rootViewController];
}

+ (void)refresh {
    SettingsUI *s = [SettingsUI shared];
    gEnabled = s.enabled;
    gFloatingButton.hidden = !gEnabled;
    gArrowOverlay.hidden = !gEnabled;
    if (gEnabled) {
        [gArrowOverlay updateWithMoves:s.lastMoves eval:s.lastEval];
    } else {
        [gArrowOverlay clear];
    }
}

@end
