#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        if (argc < 3) {
            fprintf(stderr, "Usage: FrameworkCopier <source> <destination> [nuclear:0|1]\n");
            return 1;
        }
        
        NSString *srcPath = @(argv[1]);
        NSString *dstPath = @(argv[2]);
        BOOL nuclear = (argc > 3) ? (atoi(argv[3]) == 1) : NO;
        
        NSFileManager *fman = [NSFileManager defaultManager];
        NSError *error = nil;
        
        if (nuclear) {
            if ([fman fileExistsAtPath:dstPath]) {
                if (![fman removeItemAtPath:dstPath error:&error]) {
                    NSLog(@"%@", error.localizedDescription);
                    return 1;
                }
            }
        } else {
            if ([fman fileExistsAtPath:dstPath]) {
                NSString *backupPath = [dstPath stringByAppendingString:@".old"];
                if ([fman fileExistsAtPath:backupPath]) {
                    [fman removeItemAtPath:backupPath error:nil]; // clear old backup if present
                }
                if (![fman moveItemAtPath:dstPath toPath:backupPath error:&error]) {
                    NSLog(@"%@", error.localizedDescription);
                    return 1;
                }
            }
        }
        
        if (![fman moveItemAtPath:srcPath toPath:dstPath error:&error]) {
            NSLog(@"%@", error.localizedDescription);
            return 1;
        }
        
        return 0;
    }
}