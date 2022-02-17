//
//  LuaCall.cpp
//  HYCodeScan
//
//  Created by admin on 2019/10/5.
//  Copyright © 2019 Admin. All rights reserved.
//

#include "LuaCall.hpp"
#include "lua_zlib.h"
#include "lfs.h"
#include <string>
#include <vector>

static std::vector<std::string> split(const std::string& str, const std::string& delim) {
    std::vector<std::string> res;
    if("" == str) return res;
    //先将要切割的字符串从string类型转换为char*类型
    char * strs = new char[str.length() + 1] ; //不要忘了
    strcpy(strs, str.c_str());
    
    char * d = new char[delim.length() + 1];
    strcpy(d, delim.c_str());
    
    char *p = strtok(strs, d);
    while(p) {
        std::string s = p; //分割得到的字符串转换为string类型
        res.push_back(s); //存入结果数组
        p = strtok(NULL, d);
    }
    
    return res;
}

static bool isInWait = false;

static int lua_exit(lua_State * luastate)
{
    isInWait = false;
    return 0;
}

static int lua_print(lua_State * luastate)
{
    int nargs = lua_gettop(luastate);
    
    std::string t;
    for (int i=1; i <= nargs; i++)
    {
        if (lua_istable(luastate, i))
            t += "table";
        else if (lua_isnone(luastate, i))
            t += "none";
        else if (lua_isnil(luastate, i))
            t += "nil";
        else if (lua_isboolean(luastate, i))
        {
            if (lua_toboolean(luastate, i) != 0)
                t += "true";
            else
                t += "false";
        }
        else if (lua_isfunction(luastate, i))
            t += "function";
        else if (lua_islightuserdata(luastate, i))
            t += "lightuserdata";
        else if (lua_isthread(luastate, i))
            t += "thread";
        else
        {
            const char * str = lua_tostring(luastate, i);
            if (str)
                t += lua_tostring(luastate, i);
            else
                t += lua_typename(luastate, lua_type(luastate, i));
        }
        if (i!=nargs)
            t += "\t";
    }
    printf("[LUA-print] %s\n", t.c_str());
    
    return 0;
}

void LuaCall::executeString(const char *str, bool needWait) {
    isInWait = needWait;
    if (luaL_dostring(L, str) != LUA_OK) {
        if (lua_gettop(L) != 0) {
            printf("[LUA-error] %s\n", lua_tostring(L, -1));
        }
    }
    while(isInWait);
}

void LuaCall::setLuaPath(const char* path )
{
    lua_getglobal( L, "package" );
    lua_getfield( L, -1, "path" ); // get field "path" from table at top of stack (-1)
    std::string cur_path = lua_tostring( L, -1 ); // grab path string from top of stack
    cur_path.append( ";" ); // do your path magic here
    cur_path.append( path );
    lua_pop( L, 1 ); // get rid of the string on the stack we just pushed on line 5
    lua_pushstring( L, cur_path.c_str() ); // push the new one
    lua_setfield( L, -2, "path" ); // set the field "path" in table at -2 with value at top of stack
    lua_pop( L, 1 ); // get rid of package table from top of stack
}

void LuaCall::executeFile(const char *file, bool needWait) {
    isInWait = needWait;
    if (luaL_dofile(L, file) != LUA_OK) {
        if (lua_gettop(L) != 0) {
            printf("[LUA-error] %s\n", lua_tostring(L, -1));
        }
    }
    while(isInWait);
}


void LuaCall::addLuaLoader(lua_CFunction func)
{
    if (!func) return;
    
    // stack content after the invoking of the function
    // get loader table
    lua_getglobal(L, "package");                                  /* L: package */
    lua_getfield(L, -1, "loaders");                               /* L: package, loaders */
    
    // insert loader into index 2
    lua_pushcfunction(L, func);                                   /* L: package, loaders, func */
    for (int i = (int)(luaL_len(L, -2) + 1); i > 2; --i)
    {
        lua_rawgeti(L, -2, i - 1);                                /* L: package, loaders, func, function */
        // we call lua_rawgeti, so the loader table now is at -3
        lua_rawseti(L, -3, i);                                    /* L: package, loaders, func */
    }
    lua_rawseti(L, -2, 2);                                        /* L: package, loaders */
    
    // set loaders into package
    lua_setfield(L, -2, "loaders");                               /* L: package */
    
    lua_pop(L, 1);
}

LuaCall::LuaCall() { 
    L = luaL_newstate();
    if (L == NULL)
    {
        printf("Error initializing lua!\n");
        return;
    }
    luaL_openlibs(L);
    luaopen_zlib(L);
    luaopen_lfs(L);
    const luaL_Reg global_functions [] = {
        {"exit", lua_exit},
        {"print", lua_print},
        {nullptr, nullptr}
    };
    lua_getglobal(L, "_G");
    luaL_setfuncs(L, global_functions, 0);
    lua_pop(L, 1);
    
    std::string home = [[NSBundle mainBundle].resourcePath UTF8String];
    setLuaPath((home + "/?.lua").c_str());
    setLuaPath((home + "/File/lua/?.lua").c_str());
}

LuaCall::~LuaCall() { 
    if (L) {
        lua_close(L);
    }
}

void LuaCall::setArgs(const char * _args) {
    std::string args(_args);
    std::vector<std::string> AllStr = split(args, " ");
    lua_getglobal(L, "_G");
    lua_pushstring(L, "args");
    lua_newtable(L);
    for (int i = 0; i < AllStr.size(); i++) {
        lua_pushnumber(L,i + 1);
        lua_pushstring(L, AllStr[i].c_str());
        lua_settable(L, -3);
    }
    lua_settable(L, -3);
}




