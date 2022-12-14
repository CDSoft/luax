/*
* mycompat.h
* cross-version compatibility and convenience macros for my Lua libraries
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 26 Jul 2018 17:53:25
* This code is hereby placed in the public domain and also under the MIT license
*/

/* compatibility macros */

#if LUA_VERSION_NUM <= 502

#undef  l_mathop
#define l_mathop(op)	op

#endif

#if LUA_VERSION_NUM <= 501

#define luaL_setmetatable(L,t)		\
	luaL_getmetatable(L,t);		\
	lua_setmetatable(L,-2)

#define luaL_setfuncs(L,r,n)		\
	luaL_register(L,NULL,r)

#endif

/* convenience macros */

#define luaL_boxpointer(L,u)		\
	(*(void **)(lua_newuserdata(L, sizeof(void *))) = (u))

#define	luaL_unboxpointer(L,i,t)	\
	*((void**)luaL_checkudata(L,i,t))

