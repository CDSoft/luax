/*
* mycompat.h
* cross-version compatibility and convenience macros for my Lua libraries
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 31 Jul 2018 13:52:46
* This code is hereby placed in the public domain and also under the MIT license
*/

/* compatibility macros */

#if LUA_VERSION_NUM <= 501

#define luaL_setmetatable(L,t)		\
	luaL_getmetatable(L,t);		\
	lua_setmetatable(L,-2)

#define luaL_setfuncs(L,r,n)		\
	luaL_register(L,NULL,r)

#define luaL_newlib(L,r)		\
	lua_createtable(L,0,sizeof(r)/sizeof((r)[0])-1);	\
	luaL_setfuncs(L,r,0)

#endif

/* convenience macros */

#define luaL_boxpointer(L,u)		\
	(*(void **)(lua_newuserdata(L, sizeof(void *))) = (u))

#define	luaL_unboxpointer(L,i,t)	\
	*((void**)luaL_checkudata(L,i,t))

