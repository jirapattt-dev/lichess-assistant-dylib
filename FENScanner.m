#import "FENScanner.h"
#import <mach/mach.h>
#import <mach/vm_map.h>

@implementation FENScanner

+ (instancetype)shared {
    static FENScanner *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [FENScanner new]; });
    return s;
}

- (NSString *)scanForFEN {
    // Scan readable memory regions for FEN-like strings
    mach_port_t task = mach_task_self();
    vm_address_t address = 0;
    vm_size_t size = 0;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object = MACH_PORT_NULL;

    NSString *best = nil;
    int bestScore = 0;

    while (YES) {
        kern_return_t kr = vm_region_64(task, &address, &size, VM_REGION_BASIC_INFO_64,
                                        (vm_region_info_t)&info, &count, &object);
        if (kr != KERN_SUCCESS) break;

        if ((info.protection & VM_PROT_READ) && size < 50 * 1024 * 1024) {
            char *buf = malloc(size);
            if (buf) {
                vm_size_t out = 0;
                if (vm_read_overwrite(task, address, size, (vm_address_t)buf, &out) == KERN_SUCCESS) {
                    NSString *found = [self findFENIn:buf length:out];
                    if (found) {
                        int score = (int)found.length;
                        if (score > bestScore) {
                            bestScore = score;
                            best = found;
                        }
                    }
                }
                free(buf);
            }
        }
        address += size;
    }
    return best;
}

- (NSString *)findFENIn:(char *)buf length:(vm_size_t)len {
    // Look for FEN pattern: piece placement / w|b / KQkq|- / ep / half / full
    for (vm_size_t i = 0; i + 20 < len; i++) {
        if (buf[i] != 'r' && buf[i] != 'n' && buf[i] != 'b' && buf[i] != 'q' &&
            buf[i] != 'k' && buf[i] != 'p' && buf[i] != 'R' && buf[i] != 'N' &&
            buf[i] != 'B' && buf[i] != 'Q' && buf[i] != 'K' && buf[i] != 'P' &&
            buf[i] != '1' && buf[i] != '8') continue;

        // Check for slash-separated ranks
        int slashes = 0;
        vm_size_t j = i;
        while (j < len && j < i + 80) {
            char c = buf[j];
            if (c == '/') slashes++;
            else if (c == ' ' && slashes >= 7) {
                // Found potential FEN start; extract until next non-FEN char
                vm_size_t end = j;
                while (end < len && end < j + 40 && buf[end] != '\0' && buf[end] != '\n') end++;
                if (end > j + 10) {
                    NSString *cand = [[NSString alloc] initWithBytes:buf + i length:end - i encoding:NSASCIIStringEncoding];
                    if ([self isValidFEN:cand]) return cand;
                }
                break;
            } else if (!(c >= '1' && c <= '8') &&
                       c != 'r' && c != 'n' && c != 'b' && c != 'q' && c != 'k' && c != 'p' &&
                       c != 'R' && c != 'N' && c != 'B' && c != 'Q' && c != 'K' && c != 'P' &&
                       c != '/') {
                break;
            }
            j++;
        }
    }
    return nil;
}

- (BOOL)isValidFEN:(NSString *)s {
    if (s.length < 15) return NO;
    NSArray *parts = [s componentsSeparatedByString:@" "];
    if (parts.count < 4) return NO;
    NSString *place = parts[0];
    NSArray *ranks = [place componentsSeparatedByString:@"/"];
    if (ranks.count != 8) return NO;
    for (NSString *r in ranks) {
        int sum = 0;
        for (NSUInteger i = 0; i < r.length; i++) {
            unichar c = [r characterAtIndex:i];
            if (c >= '1' && c <= '8') sum += c - '0';
            else if ([[NSCharacterSet letterCharacterSet] characterIsMember:c]) sum++;
            else return NO;
        }
        if (sum != 8) return NO;
    }
    NSString *side = parts[1];
    if (![side isEqualToString:@"w"] && ![side isEqualToString:@"b"]) return NO;
    return YES;
}

@end
