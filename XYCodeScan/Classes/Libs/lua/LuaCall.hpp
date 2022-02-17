//
//  LuaCall.hpp
//  HYCodeScan
//
//  Created by admin on 2019/10/5.
//  Copyright © 2019 Admin. All rights reserved.
//

#ifndef LuaCall_hpp
#define LuaCall_hpp

#include <stdio.h>
extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

class LuaCall
{
    lua_State *L;
    void addLuaLoader(lua_CFunction func);
    void setLuaPath(const char* path);
public:
    LuaCall();
    ~ LuaCall();
    void setArgs(const char * args);
    void executeString(const char * str, bool needWait =false);
    void executeFile(const char * file, bool needWait =false);
};

#endif /* LuaCall_hpp */
