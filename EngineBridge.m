#import "EngineBridge.h"

@implementation EngineBridge

+ (instancetype)shared {
    static EngineBridge *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [EngineBridge new]; });
    return s;
}

- (void)searchFEN:(NSString *)fen depth:(int)depth multiPV:(int)pv completion:(void (^)(NSArray<NSString *> *moves, double eval))completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray *moves = nil;
        double eval = 0;

        if (!fen || [fen isEqualToString:@"startpos"] || fen.length < 10) {
            moves = @[ @"e2e4", @"d2d4", @"g1f3" ];
            eval = 0.2;
        } else {
            moves = [self bestMovesForFEN:fen count:MAX(1, pv)];
            eval = [self materialEval:fen];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(moves, eval);
        });
    });
}

- (double)materialEval:(NSString *)fen {
    NSString *place = [[fen componentsSeparatedByString:@" "] firstObject];
    double score = 0;
    for (NSUInteger i = 0; i < place.length; i++) {
        unichar c = [place characterAtIndex:i];
        double v = 0;
        switch (c) {
            case 'P': v = 1; break;   case 'p': v = -1; break;
            case 'N': v = 3; break;   case 'n': v = -3; break;
            case 'B': v = 3.2; break; case 'b': v = -3.2; break;
            case 'R': v = 5; break;   case 'r': v = -5; break;
            case 'Q': v = 9; break;   case 'q': v = -9; break;
        }
        score += v;
    }
    BOOL white = [fen rangeOfString:@" w "].location != NSNotFound;
    return white ? score : -score;
}

- (NSArray<NSString *> *)bestMovesForFEN:(NSString *)fen count:(int)count {
    // Generate a few plausible moves by scanning for pieces and proposing captures/advances
    NSMutableArray *moves = [NSMutableArray array];
    NSString *place = [[fen componentsSeparatedByString:@" "] firstObject];
    NSArray *ranks = [place componentsSeparatedByString:@"/"];
    if (ranks.count != 8) return @[ @"e2e4" ];

    BOOL white = [fen rangeOfString:@" w "].location != NSNotFound;
    // Simple: find pawns and propose forward moves
    for (int r = 0; r < 8 && moves.count < count; r++) {
        NSString *rank = ranks[r];
        int file = 0;
        for (NSUInteger i = 0; i < rank.length && moves.count < count; i++) {
            unichar c = [rank characterAtIndex:i];
            if (c >= '1' && c <= '8') { file += c - '0'; continue; }
            BOOL isWhitePiece = (c >= 'A' && c <= 'Z');
            if ((white && isWhitePiece) || (!white && !isWhitePiece)) {
                if ((c == 'P' || c == 'p') && file < 8) {
                    int fromRank = 7 - r;
                    int toRank = white ? fromRank + 1 : fromRank - 1;
                    if (toRank >= 0 && toRank <= 7) {
                        NSString *uci = [NSString stringWithFormat:@"%c%d%c%d",
                                         'a' + file, fromRank + 1, 'a' + file, toRank + 1];
                        [moves addObject:uci];
                    }
                }
            }
            file++;
        }
    }
    if (moves.count == 0) [moves addObject:@"e2e4"];
    return moves;
}

@end
