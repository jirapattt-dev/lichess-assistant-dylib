#import <UIKit/UIKit.h>

@interface ArrowOverlay : UIView
- (void)updateWithMoves:(NSArray<NSString *> *)uciMoves eval:(double)eval;
- (void)clear;
@end
