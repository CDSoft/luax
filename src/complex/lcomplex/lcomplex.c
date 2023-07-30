/*
* lcomplex.c
* C99 complex numbers for Lua 5.3
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 26 Jul 2018 17:57:06
* This code is hereby placed in the public domain and also under the MIT license
*/

#include <complex.h>

#include "lua.h"
#include "lauxlib.h"
#include "mycompat.h"

#define Complex		LUA_NUMBER complex
#define MYNAME		"complex"
#define MYTYPE		MYNAME " number"
#define MYVERSION	MYTYPE " library for " LUA_VERSION " / Jul 2018"

#define Z(i)		Pget(L,i)
#define O(i)		luaL_optnumber(L,i,0)

#define cadd(z,w)	((z)+(w))
#define csub(z,w)	((z)-(w))
#define cmul(z,w)	((z)*(w))
#define cdiv(z,w)	((z)/(w))
#define cneg(z)		(-(z))
#define cconj		l_mathop(conj)

static Complex Pget(lua_State *L, int i)
{
 switch (lua_type(L,i))
 {
  case LUA_TNUMBER:
  case LUA_TSTRING:
   return luaL_checknumber(L,i);
  default:
   return *((Complex*)luaL_checkudata(L,i,MYTYPE));
 }
}

static int Pnew(lua_State *L, Complex z)
{
 Complex *p=lua_newuserdata(L,sizeof(Complex));
 luaL_setmetatable(L,MYTYPE);
 *p=z;
 return 1;
}

static int Leq(lua_State *L)			/** __eq(z,w) */
{
 lua_pushboolean(L,Z(1)==Z(2));
 return 1;
}

static int Ltostring(lua_State *L)		/** tostring(z) */
{
 Complex z=Z(1);
 LUA_NUMBER x=creal(z);
 LUA_NUMBER y=cimag(z);
 lua_settop(L,0);
 if (x!=0 || y==0) lua_pushnumber(L,x);
 if (y!=0)
 {
  if (y==1)
  {
   if (x!=0) lua_pushliteral(L,"+");
  }
  else if (y==-1)
   lua_pushliteral(L,"-");
  else
  {
   if (y>0 && x!=0) lua_pushliteral(L,"+");
   lua_pushnumber(L,y);
  }
  lua_pushliteral(L,"i");
 }
 lua_concat(L,lua_gettop(L));
 return 1;
}

#define A(f,e)	static int L##f(lua_State *L) { return Pnew(L,e); }
#define B(f)	A(f,l_mathop(c##f)(Z(1),Z(2)))
#define F(f)	A(f,l_mathop(c##f)(Z(1)))
#define G(f)	static int L##f(lua_State *L) { lua_pushnumber(L,l_mathop(c##f)(Z(1))); return 1; }

A(new,O(1)+O(2)*I)	/** new(x,y) */
B(add)			/** __add(z,w) */
B(div)			/** __div(z,w) */
B(mul)			/** __mul(z,w) */
B(sub)			/** __sub(z,w) */
F(neg)			/** __unm(z) */
G(abs)			/** abs(z) */
F(acos)			/** acos(z) */
F(acosh)		/** acosh(z) */
G(arg)			/** arg(z) */
F(asin)			/** asin(z) */
F(asinh)		/** asinh(z) */
F(atan)			/** atan(z) */
F(atanh)		/** atanh(z) */
F(conj)			/** conj(z) */
F(cos)			/** cos(z) */
F(cosh)			/** cosh(z) */
F(exp)			/** exp(z) */
G(imag)			/** imag(z) */
F(log)			/** log(z) */
B(pow)			/** pow(z,w) */
F(proj)			/** proj(z) */
G(real)			/** real(z) */
F(sin)			/** sin(z) */
F(sinh)			/** sinh(z) */
F(sqrt)			/** sqrt(z) */
F(tan)			/** tan(z) */
F(tanh)			/** tanh(z) */

static const luaL_Reg R[] =
{
	{ "__add",	Ladd	},
	{ "__div",	Ldiv	},
	{ "__eq",	Leq	},
	{ "__mul",	Lmul	},
	{ "__sub",	Lsub	},
	{ "__unm",	Lneg	},
	{ "abs",	Labs	},
	{ "acos",	Lacos	},
	{ "acosh",	Lacosh	},
	{ "arg",	Larg	},
	{ "asin",	Lasin	},
	{ "asinh",	Lasinh	},
	{ "atan",	Latan	},
	{ "atanh",	Latanh	},
	{ "conj",	Lconj	},
	{ "cos",	Lcos	},
	{ "cosh",	Lcosh	},
	{ "exp",	Lexp	},
	{ "imag",	Limag	},
	{ "log",	Llog	},
	{ "new",	Lnew	},
	{ "pow",	Lpow	},
	{ "proj",	Lproj	},
	{ "real",	Lreal	},
	{ "sin",	Lsin	},
	{ "sinh",	Lsinh	},
	{ "sqrt",	Lsqrt	},
	{ "tan",	Ltan	},
	{ "tanh",	Ltanh	},
	{ "tostring",	Ltostring},
	{ NULL,		NULL	}
};

LUALIB_API int luaopen_complex(lua_State *L)
{
 luaL_newmetatable(L,MYTYPE);
 luaL_setfuncs(L,R,0);
 lua_pushliteral(L,"version");			/** version */
 lua_pushliteral(L,MYVERSION);
 lua_settable(L,-3);
 lua_pushliteral(L,"__index");
 lua_pushvalue(L,-2);
 lua_settable(L,-3);
 lua_pushliteral(L,"I");			/** I */
 Pnew(L,I);
 lua_settable(L,-3);
 lua_pushliteral(L,"__pow");			/** __pow(z,w) */
 lua_pushliteral(L,"pow");
 lua_gettable(L,-3);
 lua_settable(L,-3);
 lua_pushliteral(L,"__tostring");		/** __tostring(z) */
 lua_pushliteral(L,"tostring");
 lua_gettable(L,-3);
 lua_settable(L,-3);
 return 1;
}
