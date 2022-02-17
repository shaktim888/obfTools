//
//  DFModelBuilder.m
//  DFGrok
//
//  Created by Sam Taylor on 22/05/2013.
//  Copyright (c) 2013 darkFunction Software. All rights reserved.
//

#import "DFModelBuilder.h"
#import <clang-c/Index.h>
// Definitions
#import "DFDefinition.h"
#import "DFOCClassDefinition.h"
#import "DFProtocolDefinition.h"
#import "DFPropertyDefinition.h"
#import "DFCollectionPropertyDefinition.h"
#import "DFModelBuilder.h"
#import "DFOCImplementDefinition.h"
#import "DFCXXClassDefinition.h"
#import "DFMethodDefinition.h"

static const char *_getCursorName(CXCursor cursor) {
    return clang_getCString(clang_getCursorSpelling(cursor));
}
static const char *_getTypeName(CXType cursor) {
    return clang_getCString(clang_getTypeSpelling(cursor));
}

static const char *_getFilename(CXCursor cursor) {
    CXSourceRange range = clang_getCursorExtent(cursor);
    CXSourceLocation location = clang_getRangeStart(range);
    CXFile file;
    clang_getFileLocation(location, &file, NULL, NULL, NULL);
    return clang_getCString(clang_getFileName(file));
}

void indexDeclaration(CXClientData client_data, const CXIdxDeclInfo* declaration) {
    @autoreleasepool {
        DFModelBuilder* data = (__bridge DFModelBuilder*)client_data;
        if ([data respondsToSelector:@selector(onFoundDeclaration:)]) {
            [data onFoundDeclaration:declaration];
        }
    }
}

CXIdxClientFile ppIncludedFile(CXClientData client_data, const CXIdxIncludedFileInfo* included_file) {
    @autoreleasepool {
        DFModelBuilder* modelBuilder = (__bridge DFModelBuilder*)client_data;
        if ([modelBuilder respondsToSelector: @selector(onIncludedFile:)]) {
            return [modelBuilder onIncludedFile:included_file];
        }
        return NULL;
    }
}

void indexEntityReference(CXClientData client_data, const CXIdxEntityRefInfo * entityRef) {
    @autoreleasepool {
        DFModelBuilder* modelBuilder = (__bridge DFModelBuilder*)client_data;
        if ([modelBuilder respondsToSelector: @selector(onFoundEntityReference:)]) {
            [modelBuilder onFoundEntityReference:entityRef];
        }
    }
}

@interface DFModelBuilder ( /* Private */ )
{
    DFDefinition* currentCategoryDef;
}
@property (nonatomic, readwrite) NSMutableDictionary* OCDefinitions;
@property (nonatomic, readwrite) NSMutableDictionary* CXXDefinitions;
@property (nonatomic) NSMutableDictionary* implementations;

@end

@implementation DFModelBuilder

- (instancetype) init {
    self = [super init];
    if (self) {
        self.OCDefinitions = [NSMutableDictionary dictionary];
        self.implementations = [NSMutableDictionary dictionary];
        self.CXXDefinitions = [NSMutableDictionary dictionary];
    }
    return self;
}


#pragma mark - DFClangParserDelegate

- (void)onFoundDeclaration:(const CXIdxDeclInfo *)declaration {
    const char * const cName = declaration->entityInfo->name;
    if (cName == NULL)
        return;
    
    //NSLog(@"%d -> %s", declaration->entityInfo->kind, cName);
    
    switch (declaration->entityInfo->kind) {
        case CXIdxEntity_CXXClass:
            [self processCXXClassDeclaration:declaration];
            break;
        case CXIdxEntity_ObjCClass:
            [self processOCClassDeclaration:declaration];
            break;
            
        case CXIdxEntity_ObjCProtocol:
            [self processProtocolDeclaration:declaration];
            break;
        
        case CXIdxEntity_ObjCProperty:
            [self processPropertyDeclaration:declaration];
            break;
            
        case CXIdxEntity_ObjCCategory:
        {
            const CXIdxObjCCategoryDeclInfo * descInfo = clang_index_getObjCCategoryDeclInfo(declaration);
            currentCategoryDef = self.OCDefinitions[[NSString stringWithUTF8String:descInfo->objcClass->name]];
        }
//            self.currentContainerDef = nil;
            break;
        
        case CXIdxEntity_ObjCClassMethod:
        case CXIdxEntity_ObjCInstanceMethod:
            [self processOCMethodDeclaration:declaration];
            break;
        
        case CXIdxEntity_CXXStaticMethod:
        case CXIdxEntity_CXXInstanceMethod:
            [self processCXXMethodDeclaration:declaration];
            break;
            
        default:
            break;
    }
}

- (void)onFoundEntityReference:(const CXIdxEntityRefInfo *)entityRef {
    // Not used...
}

#pragma mark - Declaration processors
- (DFOCClassDefinition*)processCXXClassDeclaration:(const CXIdxDeclInfo *)declaration {
    NSString* name = [NSString stringWithUTF8String:declaration->entityInfo->name];
    DFOCClassDefinition* classDef = (DFOCClassDefinition*)[self getDefinitionWithName:name andType:[DFCXXClassDefinition class] cursor:declaration->cursor];
    return classDef;
}

- (DFOCClassDefinition*)processOCClassDeclaration:(const CXIdxDeclInfo *)declaration {
    NSString* name = [NSString stringWithUTF8String:declaration->entityInfo->name];
    
    DFOCClassDefinition* classDef = (DFOCClassDefinition*)[self getDefinitionWithName:name andType:[DFOCClassDefinition class] cursor:declaration->cursor];
    
    if (declaration->isContainer) {
        const CXIdxObjCContainerDeclInfo* containerInfo = clang_index_getObjCContainerDeclInfo(declaration);
        if (containerInfo) {
            if (containerInfo->kind == CXIdxObjCContainer_Implementation) {
                // Found an implementation
                DFOCImplementDefinition* implDef = (DFOCImplementDefinition*)[self getDefinitionWithName:name andType:[DFOCImplementDefinition class] cursor:containerInfo->declInfo->cursor];
                implDef.declare = classDef;
                [self.implementations setObject:implDef forKey:name];
            } else if (containerInfo->kind == CXIdxObjCContainer_Interface) {
                const CXIdxObjCInterfaceDeclInfo* declarationInfo = clang_index_getObjCInterfaceDeclInfo(declaration);
                if (declarationInfo) {
                    
                    // Find superclass
                    const CXIdxBaseClassInfo* superclassInfo = declarationInfo->superInfo;
                    if (superclassInfo) {
                        const char* cName = superclassInfo->base->name;
                        if (cName) {
                            NSString* superclassName = [NSString stringWithUTF8String:cName];
                            classDef.superclassDef = (DFOCClassDefinition*)[self getDefinitionWithName:superclassName andType:[DFOCClassDefinition class] cursor:superclassInfo->cursor];
                            cName = NULL;
                        }
                    }
                    
                    // Find protocols
                    for (int i=0; i<declarationInfo->protocols->numProtocols; ++i) {
                        const CXIdxObjCProtocolRefInfo* protocolRefInfo = declarationInfo->protocols->protocols[i];
                        NSString* protocolName = [NSString stringWithFormat:@"<%@>", [NSString stringWithUTF8String:protocolRefInfo->protocol->name]];
                        
                        [self setProtocolName:protocolName onContainer:classDef cursor:protocolRefInfo->cursor];
                    }
                }
            }
        }
    }
    
    return classDef;
}

- (void)setProtocolName:(NSString*)protocolName onContainer:(DFContainerDefinition*)containerDef cursor:(CXCursor) cursor {
    DFProtocolDefinition* protocolDef = (DFProtocolDefinition*)[self getDefinitionWithName:protocolName andType:[DFProtocolDefinition class] cursor:cursor];
    if (![containerDef.protocols objectForKey:protocolName]) {
        [containerDef.protocols setObject:protocolDef forKey:protocolName];
    }
}

- (DFProtocolDefinition*)processProtocolDeclaration:(const CXIdxDeclInfo *)declaration {
    NSString* name = [NSString stringWithUTF8String:declaration->entityInfo->name];
    name = [NSString stringWithFormat:@"<%@>", name];
    
    DFProtocolDefinition* protoDef = (DFProtocolDefinition*)[self getDefinitionWithName:name andType:[DFProtocolDefinition class] cursor:declaration->cursor];
    
    // Find super protocols
    const CXIdxObjCProtocolRefListInfo* protocolRefListInfo = clang_index_getObjCProtocolRefListInfo(declaration);
    if (protocolRefListInfo) {
        for (int i=0; i<protocolRefListInfo->numProtocols; ++i) {
            const CXIdxObjCProtocolRefInfo* protocolRefInfo = protocolRefListInfo->protocols[i];
            NSString* protocolName = [NSString stringWithFormat:@"<%@>", [NSString stringWithUTF8String:protocolRefInfo->protocol->name]];
            [self setProtocolName:protocolName onContainer:protoDef cursor:protocolRefInfo->cursor];
        }
    }
    
    return protoDef;
}

- (void)processPropertyDeclaration:(const CXIdxDeclInfo *)declaration {
    NSString* name = [NSString stringWithUTF8String:declaration->entityInfo->name];
    CXCursor from = clang_getCursorLexicalParent(declaration->cursor);
    NSString * cname = [NSString stringWithUTF8String:_getCursorName(from)];
    DFDefinition * def = self.OCDefinitions[cname];
    if (def
        && [def isKindOfClass:DFContainerDefinition.class]
        && ![((DFContainerDefinition*)def).childDefinitions objectForKey:name]
        && !self.implementations[name]) {
        const CXIdxObjCPropertyDeclInfo *propertyDeclaration = clang_index_getObjCPropertyDeclInfo(declaration);
        if (propertyDeclaration) {
            NSArray* tokens = [self getStringTokensFromCursor:propertyDeclaration->declInfo->cursor];
            NSString* name = [NSString stringWithUTF8String:propertyDeclaration->declInfo->entityInfo->name];
            
            DFPropertyDefinition* propertyDef = [[DFPropertyDefinition alloc] initWithName:name andTokens:tokens];
            [((DFContainerDefinition*)def).childDefinitions setObject:propertyDef forKey:name];
        }
    }
}

- (void)processCXXMethodDeclaration:(const CXIdxDeclInfo *)declaration {
    // 这里通过具体定义位置来找。外部实现的就不去管了
    CXCursor from = clang_getCursorLexicalParent(declaration->cursor);
//    CXCursor from = clang_getCursorSemanticParent(declaration->cursor);
    NSString * cname = [NSString stringWithUTF8String:_getCursorName(from)];
    DFDefinition * def = self.CXXDefinitions[cname];
    if([def isKindOfClass:DFCXXClassDefinition.class]) {
        const char * _methodName = _getCursorName(declaration->cursor);
        NSMutableString * methodName = [NSMutableString stringWithUTF8String:_methodName];
        int num = clang_Cursor_getNumArguments(declaration->cursor);
        for(int i = 0; i < num; i++) {
            CXCursor parm = clang_Cursor_getArgument(declaration->cursor, i);
            CXType t = clang_getCursorType(parm);
            const char* typeName = _getTypeName(t);
            [methodName appendFormat:@"_%s", typeName];
        }
        if(![((DFCXXClassDefinition*)def).methods objectForKey:methodName]) {
            DFMethodDefinition * method = [[DFMethodDefinition alloc] initWithName:methodName];
            method.isStatic = declaration->entityInfo->kind == CXIdxEntity_CXXStaticMethod;
            method.filePath = [NSString stringWithUTF8String:_getFilename(declaration->cursor)];
            CXSourceRange range = clang_getCursorExtent(declaration->cursor);
            CXSourceLocation startLocation = clang_getRangeStart(range);
            CXSourceLocation endLocation = clang_getRangeEnd(range);
            unsigned startOffset;
            unsigned endOffset;
            clang_getFileLocation(startLocation, NULL, NULL, NULL, &startOffset);
            clang_getSpellingLocation(endLocation, NULL, NULL, NULL, &endOffset);

            method.startOffset = startOffset;
            method.endOffset = endOffset;
            [((DFCXXClassDefinition*)def).methods setObject:method forKey:methodName];
        }
    }
}

// Examine the code to search for multiple property relationships with arrays and dictionaries
- (void)processOCMethodDeclaration:(const CXIdxDeclInfo *)declaration {
    CXCursor from = clang_getCursorSemanticParent(declaration->cursor);
    NSString * cname = [NSString stringWithUTF8String:_getCursorName(from)];
    DFDefinition * def;
    if(from.kind == CXCursor_ObjCCategoryDecl) {
        def = currentCategoryDef;
    } else {
        def =  self.OCDefinitions[cname];
    }
    if([def isKindOfClass:DFOCClassDefinition.class]
       && !self.implementations[cname]) {
        const char * _methodName = _getCursorName(declaration->cursor);
        NSString * methodName = [NSString stringWithUTF8String:_methodName];
        DFMethodDefinition * method = [[DFMethodDefinition alloc] initWithName:methodName];
        method.isStatic = declaration->entityInfo->kind == CXIdxEntity_ObjCClassMethod;
        method.filePath = [NSString stringWithUTF8String:_getFilename(declaration->cursor)];
        CXSourceRange range = clang_getCursorExtent(declaration->cursor);
        CXSourceLocation startLocation = clang_getRangeStart(range);
        CXSourceLocation endLocation = clang_getRangeEnd(range);
        unsigned startOffset;
        unsigned endOffset;
        clang_getFileLocation(startLocation, NULL, NULL, NULL, &startOffset);
        clang_getSpellingLocation(endLocation, NULL, NULL, NULL, &endOffset);

        method.startOffset = startOffset;
        method.endOffset = endOffset;
        [((DFOCClassDefinition*)def).methods setObject:method forKey:methodName];
    }
    
    clang_visitChildrenWithBlock(declaration->cursor, ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
        
        if (cursor.kind == CXCursor_ObjCMessageExpr) {
            __block NSString* memberName = nil;
            __block NSString* referencedObjectName = nil;
            
            clang_visitChildrenWithBlock(cursor, ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
                if (cursor.kind == CXCursor_MemberRefExpr) {
                    memberName = [NSString stringWithUTF8String:clang_getCString(clang_getCursorDisplayName(cursor))];
                    referencedObjectName = [NSString stringWithUTF8String:clang_getCString(clang_getCursorDisplayName(clang_getCursorSemanticParent(clang_getCursorReferenced(cursor))))];
                } else {
                    if (memberName) {
                        __block NSString* passedClassName = nil;
                        __block NSMutableArray* passedProtocolNames = [NSMutableArray array];
                        
                        clang_visitChildrenWithBlock(cursor, ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
                            if (cursor.kind == CXCursor_DeclRefExpr) {
                                CXCursor def = clang_getCursorDefinition(cursor);
                                
                                __block int index = 0;
                                clang_visitChildrenWithBlock(def, ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
                                    NSString* token = [NSString stringWithUTF8String:clang_getCString(clang_getCursorDisplayName(cursor))];

                                    // First token is className, remaining are protocols
                                    if (!index) {
                                        passedClassName = token;
                                    } else if (token.length) {
                                        [passedProtocolNames addObject:[NSString stringWithFormat:@"<%@>", token]];
                                    }
                                    index ++;
                                    
                                    return CXChildVisit_Continue;
                                });
                            }
                            
                            return CXChildVisit_Recurse;
                        });
                        
                        DFContainerDefinition* ownerObject = [self.OCDefinitions objectForKey:referencedObjectName];
                        
                        DFPropertyDefinition* messagedProperty = [[ownerObject childDefinitions] objectForKey:memberName];
                        if (messagedProperty && passedClassName) {
                            if ([messagedProperty.typeName isEqualToString:@"NSMutableArray"] || [messagedProperty.typeName isEqualToString:@"NSMutableDictionary"]) {
                                
                                // We have discovered that passedClassName<passedProtocolNames> is passed to a mutable array or dictionary property of ownerObject,
                                // so we assume that ownerObject owns multiple passedObjects
                                
                                // Replace the array/dictionary property with a new collection property
                                DFCollectionPropertyDefinition* collectionProperty = [[DFCollectionPropertyDefinition alloc] initWithTypeName:passedClassName protocolNames:passedProtocolNames name:memberName isWeak:messagedProperty.isWeak];

                                [[ownerObject childDefinitions] setObject:collectionProperty forKey:memberName];
                            }
                        } 
                        return CXChildVisit_Break;
                    }
                }
                return CXChildVisit_Continue;
            });
        }
        return CXChildVisit_Recurse;
    });
}

#pragma mark - Utility methods

- (DFDefinition*)getDefinitionWithName:(NSString *)name andType:(Class)classType cursor:(CXCursor) cursor {
    if (![classType isSubclassOfClass:[DFDefinition class]]) {
        return nil;
    }
    DFDefinition* def;
    NSMutableDictionary * collect;
    
    if([classType isSubclassOfClass:DFOCImplementDefinition.class]) {
        collect = self.implementations;
    } else if([classType isSubclassOfClass:DFCXXClassDefinition.class]) {
        collect = self.CXXDefinitions;
    } else {
        collect = self.OCDefinitions;
    }
    def = [collect objectForKey:name];
    if (!def) {
        def = [[classType alloc] initWithName:name];
        [collect setObject:def forKey:name];
        def.filePath = [NSString stringWithUTF8String:_getFilename(cursor)];
        
        CXSourceRange range = clang_getCursorExtent(cursor);
        CXSourceLocation startLocation = clang_getRangeStart(range);
        CXSourceLocation endLocation = clang_getRangeEnd(range);
        unsigned startOffset;
        unsigned endOffset;
        clang_getFileLocation(startLocation, NULL, NULL, NULL, &startOffset);
        clang_getSpellingLocation(endLocation, NULL, NULL, NULL, &endOffset);
        
        def.startOffset = startOffset;
        def.endOffset = endOffset;
    }
    return def;
}

- (NSMutableArray*)getStringTokensFromCursor:(CXCursor)cursor {
    CXTranslationUnit translationUnit = self.translationUnit;
    CXSourceRange range = clang_getCursorExtent(cursor);
    CXToken *tokens = 0;
    unsigned int nTokens = 0;
    
    clang_tokenize(translationUnit, range, &tokens, &nTokens);
    NSMutableArray* stringTokens = [NSMutableArray arrayWithCapacity:nTokens];
    
    for (unsigned int i=0; i<nTokens; ++i) {
        CXString spelling = clang_getTokenSpelling(translationUnit, tokens[i]);
        [stringTokens addObject:[NSString stringWithUTF8String:clang_getCString(spelling)]];
        clang_disposeString(spelling);
    }
    clang_disposeTokens(translationUnit, tokens, nTokens);
    return stringTokens;
}

@end
