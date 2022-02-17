#ifndef GenLibTools_h
#define GenLibTools_h

#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif

FOUNDATION_EXPORT void genOneFile(int numOfFunc, char * saveTo);
FOUNDATION_EXPORT void compileFolder(char * folder, char * saveTo);

#endif /* GenLibTools_h */
