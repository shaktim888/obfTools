#ifndef UserConfig_h
#define UserConfig_h


@interface UserConfig  : NSObject

+ (instancetype)sharedInstance;

- (void) save;
- (void) saveToFile: (NSString *) path;
- (bool) loadFromJson : (NSString *) jsonFile;
- (void) revertToDefaultConfig;

@property (atomic,strong) NSString *xcodePath;
@property (atomic,strong) NSString *codePath;
@property (atomic,strong) NSString *targets;
@property (atomic,assign) int prop;

@property (atomic,assign) BOOL scanProjectCode;
@property (atomic,strong) NSString *backupPath;

@property (atomic,strong) NSString *luaFolder;
@property (atomic,assign) BOOL isLuaCode;
@property (atomic,assign) BOOL isUglifyLua;
@property (atomic,assign) BOOL isMinifyLua;

@property (atomic,strong) NSString *resFolder;
@property (atomic,assign) NSInteger imageMode;
@property (atomic,strong) NSString * customIgnoreFile;

@property (atomic,assign) BOOL encodeNSString;
@property (atomic,assign) BOOL encodeCString;
@property (atomic,assign) BOOL insertFunction;
@property (atomic,assign) BOOL insertCode;
@property (atomic,assign) BOOL addProperty;
@property (atomic,assign) BOOL scanType;
@property (atomic,assign) BOOL scanFunc;
@property (atomic,assign) BOOL scanVar;
@property (atomic,assign) BOOL scanProp;
@property (atomic,assign) BOOL addRubishRes;
//@property (atomic,assign) BOOL modifyFileName;
@property (atomic,assign) BOOL jsObf;
@property (atomic,assign) BOOL mmd5;
@property (atomic,assign) BOOL backup;
@property (atomic,assign) BOOL autoRenameDefine;
@property (atomic,assign) BOOL scanXib;
@property (atomic,assign) BOOL skipOptimize;
@property (atomic,assign) BOOL saveLog;

@property (atomic,assign) BOOL isAddCpp;
@property (atomic,assign) int  addCppNum;
@property (atomic,assign) BOOL isAddOC;
@property (atomic,assign) int  addOCNum;
@property (atomic,assign) BOOL isUnity;

@property (atomic,assign) int addMethodNum;

@property (atomic,assign) int stringWeight;
@property (atomic,assign) int OCWeight;
@property (atomic,assign) int stringWordMin;
@property (atomic,assign) int stringWordMax;

@property (atomic,assign) int pngquantSpeed;

@property (atomic,assign) int rubbishResMin;
@property (atomic,assign) int rubbishResMax;

@property (atomic,assign) BOOL isAddFileReDefine;
@property (atomic,assign) BOOL useKiwi;

@property (atomic,assign) BOOL udid;
@property (atomic,assign) BOOL groupRename;
@property (atomic,assign) BOOL genjs;
@property (atomic,assign) BOOL genlua;
@property (atomic,assign) BOOL insertLuaCocos;

@end

#endif /* UserConfig_h */
