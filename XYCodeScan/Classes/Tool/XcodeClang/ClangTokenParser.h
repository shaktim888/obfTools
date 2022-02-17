//
//  ClangTokenParser.h
//  HYCodeScan
//
//  Created by admin on 2020/7/22.
//

#import <Foundation/Foundation.h>
#import "clang-c/Index.h"


enum CXChildVisitResult _visitJunkCodes(CXCursor cursor,
                                        CXCursor parent,
                                        CXClientData clientData);

