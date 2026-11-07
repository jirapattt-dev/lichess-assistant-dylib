#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FloatingButton.h"
#import "SettingsUI.h"
#import "ArrowOverlay.h"
#import "EngineBridge.h"
#import "FENScanner.h"

static UIWindow *gOverlayWindow = nil;
static FloatingButton *gFloatingButton = nil;
static ArrowOverlay *gArrowOverlay = nil;
static UIView *gEvalBar = nil;
static UILabel *gEvalLabel = nil;
static BOOL gEnabled = YES;
static NSTimer *gTimer = nil;
static NSString *gLastFEN = nil;
static BOOL gPaused = NO;

@interface PassThroughWindow : UIWindow
@end
@implementation PassThroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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

    // Eval bar (left edge)
    gEvalBar = [[UIView alloc] initWithFrame:CGRectMake(4, 200, 8, 200)];
    gEvalBar.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.9];
    gEvalBar.layer.cornerRadius = 4;
    gEvalBar.userInteractionEnabled = NO;
    [root.view addSubview:gEvalBar];

    gEvalLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 190, 60, 20)];
    gEvalLabel.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightMedium];
    gEvalLabel.textColor = [UIColor whiteColor];
    gEvalLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    gEvalLabel.textAlignment = NSTextAlignmentCenter;
    gEvalLabel.layer.cornerRadius = 4;
    gEvalLabel.clipsToBounds = YES;
    gEvalLabel.userInteractionEnabled = NO;
    [root.view addSubview:gEvalLabel];

    gArrowOverlay = [[ArrowOverlay alloc] initWithFrame:root.view.bounds];
    gArrowOverlay.userInteractionEnabled = NO;
    [root.view addSubview:gArrowOverlay];

    gFloatingButton = [[FloatingButton alloc] initWithFrame:CGRectMake(20, 120, 56, 56)];
    [gFloatingButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [gFloatingButton addGestureRecognizer:lp];
    [root.view addSubview:gFloatingButton];

    [EngineBridge shared];
    [SettingsUI shared].onSettingsChanged = ^{ [self refresh]; };

    [self runSearch];

    gTimer = [NSTimer scheduledTimerWithTimeInterval:1.2 repeats:YES block:^(NSTimer *t) {
        if (!gPaused) [self runSearch];
    }];
}

+ (void)runSearch {
    SettingsUI *s = [SettingsUI shared];
    if (!s.enabled || gPaused) {
        [gArrowOverlay clear];
        gEvalBar.hidden = YES;
        gEvalLabel.hidden = YES;
        return;
    }
    gEvalBar.hidden = NO;
    gEvalLabel.hidden = NO;

    NSString *fen = [[FENScanner shared] scanForFEN];
    if (!fen) fen = gLastFEN;
    if (!fen) fen = @"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    gLastFEN = fen;

    int depth = (int)MAX(6, MIN(20, s.elo / 120));
    [[EngineBridge shared] searchFEN:fen depth:depth multiPV:(int)s.arrowCount completion:^(NSArray<NSString *> *moves, double eval) {
        s.lastMoves = moves;
        s.lastEval = eval;
        [gArrowOverlay updateWithMoves:moves eval:eval];
        [self updateEvalBar:eval];

        if (s.autoPlay && moves.count > 0) {
            double delay = s.autoPlayDelay + (arc4random_uniform(40) / 100.0);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self tryAutoPlay:moves[0]];
            });
        }
    }];
}

+ (void)updateEvalBar:(double)eval {
    CGFloat h = 200;
    CGFloat pct = 0.5 + (eval / 10.0);
    if (pct < 0.05) pct = 0.05;
    if (pct > 0.95) pct = 0.95;
    CGFloat fillH = h * pct;
    gEvalBar.frame = CGRectMake(4, 200 + (h - fillH), 8, fillH);
    gEvalBar.backgroundColor = eval >= 0
        ? [UIColor colorWithRed:0.2 green:0.75 blue:0.3 alpha:0.9]
        : [UIColor colorWithRed:0.85 green:0.25 blue:0.25 alpha:0.9];
    gEvalLabel.text = [NSString stringWithFormat:@"%+.1f", eval];
}

+ (void)tryAutoPlay:(NSString *)uci {
    // Placeholder: real auto-play needs board coordinate mapping.
    // For now just log; full tap simulation requires finding the Flutter view.
    NSLog(@"[LA] auto-play candidate: %@", uci);
}

+ (void)buttonTapped {
    [[SettingsUI shared] presentFrom:gOverlayWindow.rootViewController];
}

+ (void)longPress:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) {
        gPaused = !gPaused;
        gFloatingButton.alpha = gPaused ? 0.4 : 1.0;
        if (gPaused) [gArrowOverlay clear];
    }
}

+ (void)refresh {
    SettingsUI *s = [SettingsUI shared];
    gEnabled = s.enabled;
    gFloatingButton.hidden = !gEnabled;
    gArrowOverlay.hidden = !gEnabled;
    gEvalBar.hidden = !gEnabled;
    gEvalLabel.hidden = !gEnabled;
    if (gEnabled && !gPaused) {
        [gArrowOverlay updateWithMoves:s.lastMoves eval:s.lastEval];
    } else {
        [gArrowOverlay clear];
    }
}

@end
