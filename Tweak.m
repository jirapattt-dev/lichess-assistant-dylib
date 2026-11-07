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

    gOverlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    gOverlayWindow.windowLevel = UIWindowLevelAlert + 1;
    gOverlayWindow.backgroundColor = [UIColor clearColor];
    gOverlayWindow.userInteractionEnabled = YES;
    gOverlayWindow.hidden = NO;

    UIViewController *root = [UIViewController new];
    root.view.backgroundColor = [UIColor clearColor];
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
