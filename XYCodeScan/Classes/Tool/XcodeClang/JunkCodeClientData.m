//
//  JunkCodeClientData.m
//  HYCodeScan
//
//  Created by admin on 2020/7/22.
//

#import "JunkCodeClientData.h"
#import "HYGenerateNameTool.h"
@interface JunkCodeClientData()
{
    NSString * preCode;
    unsigned int _curOffset;
    NSString * obfStringMethodCall;
    NSString * obfStringContent;
}
@end

@implementation JunkCodeClientData

- (instancetype) initWithFile:(NSString *) f
{
    self = [self init];
    if (self) {
        _curOffset = 0;
        preCode = nil;
        self.file = f;
        obfStringContent = nil;
        self.rootBlock = [[ClangBlock alloc] initWithCursor:self cursor:clang_getNullCursor() parent:nil];
        self.curBlock = self.rootBlock;
        self.stringArr = [NSMutableArray array];
    }
    return self;
}

// setter
- (void)setFile:(NSString *)file {
    _file = file.copy;
    _fileData = [NSData dataWithContentsOfFile:_file];
    _fileContent = [[NSString alloc] initWithData:_fileData encoding:NSUTF8StringEncoding];
    _file_int_data_length = _fileData.length;
}

- (NSString*) updateContent {
    NSMutableString * all = [NSMutableString string];
    [all appendString:preCode];
    [all appendString:[self getStringObfCode]];
    NSString * code = [self.rootBlock updateContent];
    [all appendString:code];
    return all;
}

- (const char *) getObfMethodCall
{
    [self getStringObfCode];
    return [obfStringMethodCall UTF8String];
}

- (NSString*) getStringObfCode {
    if(obfStringContent) {
        return obfStringContent;
    }
    NSString * boolVarName = [NSString stringWithFormat:@"_string_flag_%@", [HYGenerateNameTool generateByName:VarName from:nil cache:false]];
    NSString * methodName = [NSString stringWithFormat:@"_string_method_%@", [HYGenerateNameTool generateByName:FuncName from:nil cache:false]];
    obfStringMethodCall = [methodName stringByAppendingString:@"();"];
    
    NSMutableString * methodCode = [NSMutableString string];
    NSMutableString * staticCode = [NSMutableString string];
    [methodCode appendFormat:@"static void %@() {\n", methodName];
    [methodCode appendFormat:@"static unsigned char %@ = 0;\n", boolVarName];
    [methodCode appendFormat:@"if(!%@){\n", boolVarName];
    [methodCode appendFormat:@"%@ = 1;\n", boolVarName];

    for(int i = 0; i < [_stringArr count]; i++) {
        NSString * str = [_stringArr objectAtIndex:i];
        bool isOCStr = [str hasPrefix:@"@"];
        NSString * strVarName = [NSString stringWithFormat:@"__STRING_VALUE_REF_%d", i + 1];
        NSRange range = [str rangeOfString:@"\""];
        size_t p = range.location;
        NSMutableString * obf_v = [NSMutableString string];
        [obf_v appendString:@"{"];
        int c = 0;
        for(size_t j = p + 1; j < [str length]; j++) {
            char v = [str characterAtIndex:j];
            if(j == [str length] - 1) {
                v = 0;
            }
            int rv = arc4random() % 256;
            if(c == 0) {
                [obf_v appendFormat:@"%d", (int)((char)(v ^ rv))];
            } else {
                [obf_v appendFormat:@",%d", (int)((char)(v ^ rv))];
            }
            if(isOCStr) {
                [methodCode appendFormat:@"oc_%@[%d]^=%d;\n", strVarName, c, rv];
            } else {
                [methodCode appendFormat:@"%@[%d]^=%d;\n", strVarName, c, rv];
            }
            c++;
        }
        [obf_v appendString:@"}"];
        if(isOCStr) {
            [methodCode appendFormat:@"%@ = [NSString stringWithUTF8String:oc_%@];\n", strVarName, strVarName];
            [staticCode appendFormat:@"static char oc_%@[] = %@;\n", strVarName, obf_v];
            [staticCode appendFormat:@"static NSString * %@;\n", strVarName];
        } else {
            [staticCode appendFormat:@"static char %@[] = %@;\n", strVarName, obf_v];
        }
    }
    [methodCode appendString:@"}\n"];
    [methodCode appendString:@"}\n"];
    obfStringContent = [NSString stringWithFormat:@"%@%@", staticCode, methodCode];
    return obfStringContent;
}

- (enum CXChildVisitResult) enterCursor : (CXCursor) current parent:(CXCursor) parent
{
    CXSourceRange range = clang_getCursorExtent(current);
    CXSourceLocation startLocation = clang_getRangeStart(range);
    unsigned int offset;
    clang_getFileLocation(startLocation, NULL, NULL, NULL, &offset);
    if(!preCode) {
        [self.rootBlock setPreOffset:offset];
        // 当前节点的内容描述
        NSData* cont = [self.fileData subdataWithRange:NSMakeRange(0, offset)];
        preCode = [[NSString alloc] initWithData:cont encoding:NSUTF8StringEncoding];
    }
    if(_curOffset >= offset) {
        return CXChildVisit_Continue;
    }
    _curOffset = offset;
    return [self.curBlock enterBlock:current parent:parent];
}

- (void) obfAll : (DFModelBuilder*) modelBuilder {
    [self.rootBlock OBF:modelBuilder];
}

@end
