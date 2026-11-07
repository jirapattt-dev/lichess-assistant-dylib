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
        self.opaque = NO;
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

    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    // Board is typically centered, slightly above middle on phones
    CGFloat side = MIN(w, h) * 0.92;
    CGFloat x = (w - side) / 2.0;
    CGFloat y = (h - side) / 2.0 - (h * 0.04);
    CGRect board = CGRectMake(x, y, side, side);
    CGFloat sq = side / 8.0;

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);

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
        CGFloat alpha = 0.9 - (i * 0.15);
        if (i == 0) {
            color = (_eval >= 0)
                ? [UIColor colorWithRed:0.15 green:0.78 blue:0.28 alpha:alpha]
                : [UIColor colorWithRed:0.90 green:0.22 blue:0.22 alpha:alpha];
        } else {
            color = [UIColor colorWithRed:0.25 green:0.48 blue:0.92 alpha:alpha * 0.75];
        }

        CGFloat lineW = 8.0 - i * 1.8;
        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        CGContextSetLineWidth(ctx, lineW);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextSetLineJoin(ctx, kCGLineJoinRound);
        CGContextMoveToPoint(ctx, from.x, from.y);
        CGContextAddLineToPoint(ctx, to.x, to.y);
        CGContextStrokePath(ctx);

        // Arrow head
        CGFloat angle = atan2(to.y - from.y, to.x - from.x);
        CGFloat headLen = 18.0;
        CGPoint p1 = CGPointMake(to.x - headLen * cos(angle - 0.45),
                                 to.y - headLen * sin(angle - 0.45));
        CGPoint p2 = CGPointMake(to.x - headLen * cos(angle + 0.45),
                                 to.y - headLen * sin(angle + 0.45));
        CGContextSetLineWidth(ctx, lineW * 0.85);
        CGContextMoveToPoint(ctx, to.x, to.y);
        CGContextAddLineToPoint(ctx, p1.x, p1.y);
        CGContextMoveToPoint(ctx, to.x, to.y);
        CGContextAddLineToPoint(ctx, p2.x, p2.y);
        CGContextStrokePath(ctx);
    }

    CGContextRestoreGState(ctx);
}

@end
