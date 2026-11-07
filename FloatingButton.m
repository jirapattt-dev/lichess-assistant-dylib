#import "FloatingButton.h"

@implementation FloatingButton {
    CGPoint _lastPoint;
    BOOL _dragging;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.49 green:0.66 blue:0.32 alpha:0.92];
        self.layer.cornerRadius = 28;
        self.clipsToBounds = YES;
        [self setTitle:@"♟" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 4;

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *superview = self.superview;
    if (!superview) return;

    CGPoint translation = [pan translationInView:superview];
    if (pan.state == UIGestureRecognizerStateBegan) {
        _lastPoint = self.center;
        _dragging = YES;
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(_lastPoint.x + translation.x, _lastPoint.y + translation.y);
        CGFloat half = self.bounds.size.width / 2;
        newCenter.x = MAX(half, MIN(superview.bounds.size.width - half, newCenter.x));
        newCenter.y = MAX(half + 40, MIN(superview.bounds.size.height - half - 40, newCenter.y));
        self.center = newCenter;
    } else {
        _dragging = NO;
    }
}

@end
