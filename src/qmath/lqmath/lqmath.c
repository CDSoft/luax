/*
* lqmath.c
* rational number library for Lua based on imath
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 12 Apr 2023 17:37:25
* This code is hereby placed in the public domain and also under the MIT license
*/

#include <stdlib.h>
#include <string.h>

#include "src/imrat.h"

#include "lua.h"
#include "lauxlib.h"
#include "mycompat.h"

#define MYNAME		"qmath"
#define MYVERSION	MYNAME " library for " LUA_VERSION " / Apr 2023"
#define MYTYPE		MYNAME " rational"

static int report(lua_State *L, mp_result rc, int n)
{
 if (rc!=MP_OK)
  return luaL_error(L,"(qmath) %s",mp_error_string(rc));
 else
  return n;
}

static mp_rat Pnew(lua_State *L)
{
 mp_rat x=(mp_rat)lua_newuserdata(L,sizeof(mpq_t));
 luaL_setmetatable(L,MYTYPE);
 mp_rat_init(x);
 return x;
}

static mp_rat Pget(lua_State *L, int i)
{
 luaL_checkany(L,i);
 switch (lua_type(L,i))
 {
  case LUA_TNUMBER:
  {
   mp_small a=luaL_checkinteger(L,i);
   mp_rat x=Pnew(L);
   report(L,mp_rat_set_value(x,a,1),0);
   return x;
  }
  case LUA_TSTRING:
  {
   const char *s=lua_tostring(L,i);
   mp_rat x=Pnew(L);
   report(L,mp_rat_read_ustring(x,10,s,NULL),0);
   return x;
  }
  default:
   return luaL_checkudata(L,i,MYTYPE);
 }
 return NULL;
}

static int Lnew(lua_State *L)			/** new(x,[d]) */
{
 if (lua_gettop(L)>=2)
 {
  mp_small a=luaL_checkinteger(L,1);
  mp_small b=luaL_checkinteger(L,2);
  mp_rat x=Pnew(L);
  return report(L,mp_rat_set_value(x,a,b),1);
 }
 Pget(L,1);
 return 1;
}

static int Ltostring(lua_State *L)		/** tostring(x) */
{
 mp_rat a=Pget(L,1);
 mp_result rc=mp_rat_string_len(a,10);
 int l=rc;
 char *s=malloc(l);
 if (s==NULL) return 0;
 rc=mp_rat_to_string(a,10,s,l);
 if (rc==MP_OK)
 {
  char *t=strchr(s,'/');
  if (t!=NULL && t[1]=='1' && t[2]==0) t[0]=0;
  lua_pushstring(L,s);
 }
 free(s);
 return report(L,rc,1);
}

static int Ltodecimal(lua_State *L)		/** todecimal(x,[n]) */
{
 mp_rat a=Pget(L,1);
 mp_small m=luaL_optinteger(L,2,0);
 mp_small n= (m<0) ? 0 : m;
 mp_result rc=mp_rat_decimal_len(a,10,n);
 int l=rc;
 char *s=malloc(l);
 if (s==NULL) return 0;
 rc=mp_rat_to_decimal(a,10,n,MP_ROUND_HALF_UP,s,l);
 if (rc==MP_OK) lua_pushstring(L,s);
 free(s);
 return report(L,rc,1);
}

static int Ltonumber(lua_State *L)		/** tonumber(x) */
{
 lua_settop(L,1);
 lua_pushinteger(L,40);
 Ltodecimal(L);
 lua_pushnumber(L,lua_tonumber(L,-1));
 return 1;
}

static int Pdo1(lua_State *L, mp_result (*f)(mp_rat a, mp_rat c))
{
 mp_rat a=Pget(L,1);
 mp_rat c=Pnew(L);
 return report(L,f(a,c),1);
}

static int Pdo2(lua_State *L, mp_result (*f)(mp_rat a, mp_rat b, mp_rat c))
{
 mp_rat a=Pget(L,1);
 mp_rat b=Pget(L,2);
 mp_rat c=Pnew(L);
 return report(L,f(a,b,c),1);
}

static int Lnumer(lua_State *L)			/** numer(x) */
{
 mp_rat a=Pget(L,1);
 mp_int b=mp_rat_numer_ref(a);
 mp_rat c=Pnew(L);
 return report(L,mp_rat_add_int(c,b,c),1);
}

static int Ldenom(lua_State *L)			/** denom(x) */
{
 mp_rat a=Pget(L,1);
 mp_int b=mp_rat_denom_ref(a);
 mp_rat c=Pnew(L);
 return report(L,mp_rat_add_int(c,b,c),1);
}

static int Lsign(lua_State *L)			/** sign(x) */
{
 mp_rat a=Pget(L,1);
 lua_pushinteger(L,mp_rat_compare_zero(a));
 return 1;
}

static int Lcompare(lua_State *L)		/** compare(x,y) */
{
 mp_rat a=Pget(L,1);
 mp_rat b=Pget(L,2);
 lua_pushinteger(L,mp_rat_compare(a,b));
 return 1;
}

static int Leq(lua_State *L)
{
 mp_rat a=Pget(L,1);
 mp_rat b=Pget(L,2);
 lua_pushboolean(L,mp_rat_compare(a,b)==0);
 return 1;
}

static int Lle(lua_State *L)
{
 mp_rat a=Pget(L,1);
 mp_rat b=Pget(L,2);
 lua_pushboolean(L,mp_rat_compare(a,b)<=0);
 return 1;
}

static int Llt(lua_State *L)
{
 mp_rat a=Pget(L,1);
 mp_rat b=Pget(L,2);
 lua_pushboolean(L,mp_rat_compare(a,b)<0);
 return 1;
}

static int Liszero(lua_State *L)		/** iszero(x) */
{
 mp_rat a=Pget(L,1);
 lua_pushboolean(L,mp_rat_compare_zero(a)==0);
 return 1;
}

static int Lisinteger(lua_State *L)		/** isinteger(x) */
{
 mp_rat a=Pget(L,1);
 lua_pushboolean(L,mp_rat_is_integer(a));
 return 1;
}

static int Lneg(lua_State *L)			/** neg(x) */
{
 return Pdo1(L,mp_rat_neg);
}

static int Labs(lua_State *L)			/** abs(x) */
{
 return Pdo1(L,mp_rat_abs);
}

static int Lint(lua_State *L)			/** int(x) */
{
 mp_rat a=Pget(L,1);
 mp_int n=mp_rat_numer_ref(a);
 mp_int d=mp_rat_denom_ref(a);
 mp_int q=mp_int_alloc();
 mp_rat c=Pnew(L);
 if (q==NULL) return 0;
 report(L,mp_int_div(n,d,q,NULL),0);
 return report(L,mp_rat_add_int(c,q,c),1);
}

static int Linv(lua_State *L)			/** inv(x) */
{
 return Pdo1(L,mp_rat_recip);
}

static int Ladd(lua_State *L)			/** add(x,y) */
{
 return Pdo2(L,mp_rat_add);
}

static int Lsub(lua_State *L)			/** sub(x,y) */
{
 return Pdo2(L,mp_rat_sub);
}

static int Lmul(lua_State *L)			/** mul(x,y) */
{
 return Pdo2(L,mp_rat_mul);
}

static int Ldiv(lua_State *L)			/** div(x,y) */
{
 mp_rat a=Pget(L,1);
 mp_rat b=Pget(L,2);
 mp_rat c=Pnew(L);
 return report(L,mp_rat_div(a,b,c),1);
}

static int Lpow(lua_State *L)			/** pow(x,y) */
{
 mp_rat a=Pget(L,1);
 mp_small b=luaL_checkinteger(L,2);
 mp_rat c=Pnew(L);
 if (b<0)
 {
  report(L,mp_rat_expt(a,-b,c),0);
  return report(L,mp_rat_recip(c,c),1);
 }
 else
  return report(L,mp_rat_expt(a,b,c),1);
}

static int Lgc(lua_State *L)
{
 mp_rat x=Pget(L,1);
 mp_rat_clear(x);
 lua_pushnil(L);
 lua_setmetatable(L,1);
 return 0;
}

static const luaL_Reg R[] =
{
	{ "__add",	Ladd	},		/** __add(x,y) */
	{ "__div",	Ldiv	},		/** __div(x,y) */
	{ "__eq",	Leq	},		/** __eq(x,y) */
	{ "__gc",	Lgc	},
	{ "__le",	Lle	},		/** __le(x,y) */
	{ "__lt",	Llt	},		/** __lt(x,y) */
	{ "__mul",	Lmul	},		/** __mul(x,y) */
	{ "__pow",	Lpow	},		/** __pow(x,y) */
	{ "__sub",	Lsub	},		/** __sub(x,y) */
	{ "__tostring",	Ltostring},		/** __tostring(x) */
	{ "__unm",	Lneg	},		/** __unm(x) */
	{ "abs",	Labs	},
	{ "add",	Ladd	},
	{ "compare",	Lcompare},
	{ "denom",	Ldenom	},
	{ "div",	Ldiv	},
	{ "int",	Lint	},
	{ "inv",	Linv	},
	{ "isinteger",	Lisinteger},
	{ "iszero",	Liszero	},
	{ "mul",	Lmul	},
	{ "neg",	Lneg	},
	{ "new",	Lnew	},
	{ "numer",	Lnumer	},
	{ "pow",	Lpow	},
	{ "sign",	Lsign	},
	{ "sub",	Lsub	},
	{ "todecimal",	Ltodecimal},
	{ "tonumber",	Ltonumber},
	{ "tostring",	Ltostring},
	{ NULL,		NULL	}
};

LUALIB_API int luaopen_qmath(lua_State *L)
{
 luaL_newmetatable(L,MYTYPE);
 luaL_setfuncs(L,R,0);
 lua_pushliteral(L,"version");			/** version */
 lua_pushliteral(L,MYVERSION);
 lua_settable(L,-3);
 lua_pushliteral(L,"__index");
 lua_pushvalue(L,-2);
 lua_settable(L,-3);
 return 1;
}
