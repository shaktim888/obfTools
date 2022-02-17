//
//  XCM_Handler.hpp
//  HYCodeScan
//
//  Created by admin on 2020/7/28.
//

#ifndef XCM_Handler_hpp
#define XCM_Handler_hpp

#include <stdio.h>
#include "XTypeDelegate.h"
#include "XOCClass.hpp"
#include "XOCEnum.hpp"
#include "XOCInterface.hpp"

namespace hygen
{

class CM_Handler : public TypeDelegate
{
    std::map<std::string, BaseClass *> classMap;
    std::vector<OCInterface *> interfaceArr;
    std::vector<OCClass *> allCls;
    std::vector<OCClass *> customCls;
    
    void loadAllInterface();
    void loadAllType();
    void loadSupportTypes();
    
    int interfaceTotalWeight;
    void addDep(Context * context, std::string clsName);
    void removeDep(Context * context, std::string clsName);
public:
    CM_Handler();
    
    void onCall(Context*, Var*) override;
    
    std::string newInst(Context*, std::string& typeName, float &maxValue, float &minValue, bool forceCreate) override;
    
    int supportMode() override;
    
    void supportTypes(CodeMode cmode, bool isRun, std::vector<struct TypeWeight*> &vec) override;
    
    std::string formatName(Context*, std::string) override;
    
    std::string getBooleanValue(hygen::Context *context, hygen::Var *var, bool isTrue) override;
    
};

}

#endif /* XCM_Handler_hpp */
