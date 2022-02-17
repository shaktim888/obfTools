#ifndef LUA_ZLIB_H
#define LUA_ZLIB_H
#if __cplusplus
extern "C" {
#endif

#include "lauxlib.h"
#include "lua.h"

LUALIB_API int luaopen_zlib(lua_State * const L);

#if __cplusplus
}
#endif
#endif
