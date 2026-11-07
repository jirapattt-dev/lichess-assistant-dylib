#import <Foundation/Foundation.h>

@interface FENScanner : NSObject
+ (instancetype)shared;
- (NSString *)scanForFEN;
@end
