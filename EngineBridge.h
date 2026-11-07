#import <Foundation/Foundation.h>

@interface EngineBridge : NSObject
+ (instancetype)shared;
- (void)searchFEN:(NSString *)fen depth:(int)depth multiPV:(int)pv completion:(void (^)(NSArray<NSString *> *moves, double eval))completion;
@end
