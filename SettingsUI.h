#import <UIKit/UIKit.h>

@interface SettingsUI : NSObject
+ (instancetype)shared;
@property (nonatomic, copy) void (^onSettingsChanged)(void);
@property (nonatomic, readonly) BOOL enabled;
@property (nonatomic, readonly) NSInteger elo;
@property (nonatomic, readonly) NSInteger arrowCount;
@property (nonatomic, readonly) BOOL autoPlay;
@property (nonatomic, readonly) double autoPlayDelay;
@property (nonatomic, readonly) BOOL useMaia;
@property (nonatomic, strong) NSArray<NSString *> *lastMoves;
@property (nonatomic, assign) double lastEval;
- (void)presentFrom:(UIViewController *)vc;
@end
