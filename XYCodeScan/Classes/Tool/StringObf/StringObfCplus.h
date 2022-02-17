#ifndef StringObfCplus_h
#define StringObfCplus_h

extern void buildStringObf();
extern char * ObfOC(const char* str);
extern char * ObfCPtr(const char* str);
extern char * importObfHead();
extern void saveObfToFolder(char * path);

#endif /* StringObfCplus_h */
