#import "EngineBridge.h"

@implementation EngineBridge

+ (instancetype)shared {
    static EngineBridge *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [EngineBridge new]; });
    return s;
}

- (void)searchFEN:(NSString *)fen depth:(int)depth multiPV:(int)pv completion:(void (^)(NSArray<NSString *> *moves, double eval))completion {
    // Placeholder: real engine integration would spawn Stockfish UCI here.
    // For now return a sample move so the overlay can be tested.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray *moves = @[ @"e2e4", @"d2d4", @"g1f3" ];
        double eval = 0.3;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(moves, eval);
        });
    });
}

@end
