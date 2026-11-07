#import "ArrowOverlay.h"

@implementation ArrowOverlay {
    NSArray<NSString *> *_moves;
    double _eval;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)updateWithMoves:(NSArray<NSString *> *)uciMoves eval:(double)eval {
    _moves = [uciMoves copy];
    _eval = eval;
    [self setNeedsDisplay];
}

- (void)clear {
    _moves = nil;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!_moves.count) return;

    // Estimate board area (center-ish, square)
    CGFloat side = MIN(self.bounds.size.width, self.bounds.size.height) * 0.85;
    CGFloat x = (self.bounds.size.width - side) / 2;
    CGFloat y = (self.bounds.size.height - side) / 2 - 40;
    CGRect board = CGRectMake(x, y, side, side);
    CGFloat sq = side / 8.0;

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    for (NSUInteger i = 0; i < _moves.count && i < 3; i++) {
        NSString *uci = _moves[i];
        if (uci.length < 4) continue;
        int fromFile = [uci characterAtIndex:0] - 'a';
        int fromRank = [uci characterAtIndex:1] - '1';
        int toFile   = [uci characterAtIndex:2] - 'a';
        int toRank   = [uci characterAtIndex:3] - '1';
        if (fromFile < 0 || fromFile > 7 || fromRank < 0 || fromRank > 7) continue;
        if (toFile < 0 || toFile > 7 || toRank < 0 || toRank > 7) continue;

        CGPoint from = CGPointMake(board.origin.x + (fromFile + 0.5) * sq,
                                   board.origin.y + (7 - fromRank + 0.5) * sq);
        CGPoint to   = CGPointMake(board.origin.x + (toFile + 0.5) * sq,
                                   board.origin.y + (7 - toRank + 0.5) * sq);

        UIColor *color;
        if (i == 0) {
            color = (_eval >= 0) ? [UIColor colorWithRed:0.2 green:0.75 blue:0.3 alpha:0.85]
                                 : [UIColor colorWithRed:0.85 green:0.25 blue:0.25 alpha:0.85];
        } else {
            color = [UIColor colorWithRed:0.3 green:0.5 blue:0.9 alpha:0.6];
        }

        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        CGContextSetLineWidth(ctx, 6.0 - i * 1.5);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextMoveToPoint(ctx, from.x, from.y);
        CGContextAddLineToPoint(ctx, to.x, to.y);
        CGContextStrokePath(ctx);

        // Arrow head
        CGFloat angle = atan2(to.y - from.y, to.x - from.x);
        CGFloat headLen = 14;
        CGPoint p1 = CGPointMake(to.x - headLen * cos(angle - 0.4),
                                 to.y - headLen * sin(angle - 0.4));
        CGPoint p2 = CGPointMake(to.x - headLen * cos(angle + 0.4),
                                 to.y - headLen * sin(angle + 0.4));
        CGContextMoveToPoint(ctx, to.x, to.y);
        CGContextAddLineToPoint(ctx, p1.x, p1.y);
        CGContextMoveToPoint(ctx, to.x, to.y);
        CGContextAddLineToPoint(ctx, p2.x, p2.y);
        CGContextStrokePath(ctx);
    }
}

@end
