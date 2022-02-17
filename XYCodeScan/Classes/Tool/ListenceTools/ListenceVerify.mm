#import "ListenceTools.hpp"
#import "ListenceVerify.h"

@implementation listence

+ (bool) verify
{
    return MachineCode::verifyMachineCode();
}

@end
