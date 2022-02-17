#ifndef NameGeneratorExtern_h
#define NameGeneratorExtern_h

#if defined(__cplusplus)
extern "C" {
#endif
enum HYReNameType
{
    CSkip = 0,
    CTypeName = 1,
    CFuncName = 2,
    CVarName = 3,
    CArgName = 4,
    CWordName = 5,
    CResName = 6,
};

const char * genNameForCplus(int,bool);
void genNameClearCache(int);


#if defined(__cplusplus)
}
#endif

#endif /* NameGeneratorExtern_h */
