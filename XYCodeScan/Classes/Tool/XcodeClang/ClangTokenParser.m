//
//  ClangTokenParser.m
//  HYCodeScan
//
//  Created by admin on 2020/7/22.
//

#import "ClangTokenParser.h"
#import "JunkCodeClientData.h"

static const char *_getFilename(CXCursor cursor) {
    CXSourceRange range = clang_getCursorExtent(cursor);
    CXSourceLocation location = clang_getRangeStart(range);
    CXFile file;
    clang_getFileLocation(location, &file, NULL, NULL, NULL);
    return clang_getCString(clang_getFileName(file));
}

static bool _isFromFile(const char *filepath, CXCursor cursor) {
    if (filepath == NULL) return 0;
    const char *cursorPath = _getFilename(cursor);
    if (cursorPath == NULL) return 0;
    return strstr(cursorPath, filepath) != NULL;
}

static const char *_getCursorName(CXCursor cursor) {
    return clang_getCString(clang_getCursorSpelling(cursor));
}

// 花指令
enum CXChildVisitResult _visitJunkCodes(CXCursor cursor,
                                        CXCursor parent,
                                        CXClientData clientData) {
    if (clientData == NULL) return CXChildVisit_Break;
    
    JunkCodeClientData *data = (__bridge JunkCodeClientData *)clientData;
    if (!_isFromFile(data.file.UTF8String, cursor)) return CXChildVisit_Continue;
    
    return [data enterCursor:cursor parent:parent];
}
