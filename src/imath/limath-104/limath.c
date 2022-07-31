/*
* limath.c
* big-integer library for Lua based on imath
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 03 Jun 2019 08:43:09
* This code is hereby placed in the public domain and also under the MIT license
*/

#include <stdlib.h>

#include "src/imath.h"

#include "lua.h"
#include "lauxlib.h"
#include "mycompat.h"

#define MYNAME		"imath"
#define MYVERSION	MYNAME " library for " LUA_VERSION " / Jul 2019"
#define MYTYPE		MYNAME " biginteger"

static int report(lua_State *L, mp_result rc, int n)
{
 if (rc!=MP_OK)
  return luaL_error(L,"(imath) %s",mp_error_string(rc));
 else
  return n;
}

static mp_size Pgetbase(lua_State *L, int i)
{
 mp_size b=luaL_optinteger(L,i,10);
 if (b < MP_MIN_RADIX || b > MP_MAX_RADIX) report(L,MP_RANGE,0);
 return b;
}

static mp_int Pnew(lua_State *L)
{
 mp_int x=(mp_int)lua_newuserdata(L,sizeof(mpz_t));
 luaL_setmetatable(L,MYTYPE);
 mp_int_init(x);
 return x;
}

static mp_int Pgetstring(lua_State *L, int i, mp_size b)
{
 const char *s=lua_tostring(L,i);
 mp_int x=Pnew(L);
 report(L,mp_int_read_string(x,b,s),0);
 return x;
}

static mp_int Pget(lua_State *L, int i)
{
 luaL_checkany(L,i);
 switch (lua_type(L,i))
 {
  case LUA_TNUMBER:
  {
   mp_small a=luaL_checkinteger(L,i);
   mp_int x=Pnew(L);
   report(L,mp_int_init_value(x,a),0);
   return x;
  }
  case LUA_TSTRING:
   return Pgetstring(L,i,10);
  default:
   return luaL_checkudata(L,i,MYTYPE);
 }
 return NULL;
}

static int Lnew(lua_State *L)			/** new(x,[base]) */
{
 if (lua_gettop(L)>=2)
 {
  luaL_checktype(L,1,LUA_TSTRING);
  Pgetstring(L,1,Pgetbase(L,2));
 }
 else
  Pget(L,1);
 return 1;
}

static int Ltext(lua_State *L)			/** text(t) */
{
 size_t l;
 unsigned char *s=(unsigned char *)luaL_checklstring(L,1,&l);
 mp_int x=Pnew(L);
 report(L,mp_int_read_unsigned(x,s,l),0);
 return 1;
}

static int Ltostring(lua_State *L)		/** tostring(x,[base]) */
{
 int l;
 char *s;
 mp_int a=Pget(L,1);
 mp_size b=Pgetbase(L,2);
 mp_result rc=mp_int_string_len(a,b);
 if (rc<0) return report(L,rc,0);
 l=rc;
 s=malloc(l);
 if (s==NULL) return 0;
 rc=mp_int_to_string(a,b,s,l);
 if (rc==MP_OK) lua_pushstring(L,s);
 free(s);
 return report(L,rc,1);
}

static int Ltotext(lua_State *L)		/** totext(x) */
{
 int l;
 char *s;
 mp_int a=Pget(L,1);
 mp_result rc=mp_int_unsigned_len(a);
 if (rc<0) return report(L,rc,0);
 l=rc;
 s=malloc(l);
 if (s==NULL) return 0;
 rc=mp_int_to_unsigned(a,(unsigned char*)s,l);
 if (rc==MP_OK) lua_pushlstring(L,s,l);
 free(s);
 return report(L,rc,1);
}

static int Ltonumber(lua_State *L)		/** tonumber(x) */
{
 mp_small v;
 mp_int a=Pget(L,1);
 report(L,mp_int_to_int(a,&v),0);
 lua_pushinteger(L,v);
 return 1;
}

static int Pdo1(lua_State *L, mp_result (*f)(mp_int a, mp_int c))
{
 mp_int a=Pget(L,1);
 mp_int c=Pnew(L);
 return report(L,f(a,c),1);
}

static int Pdo2(lua_State *L, mp_result (*f)(mp_int a, mp_int b, mp_int c))
{
 mp_int a=Pget(L,1);
 mp_int b=Pget(L,2);
 mp_int c=Pnew(L);
 return report(L,f(a,b,c),1);
}

static int Lbits(lua_State *L)			/** bits(x) */
{
 mp_int a=Pget(L,1);
 lua_pushinteger(L,mp_int_count_bits(a));
 return 1;
}

static int Lcompare(lua_State *L)		/** compare(x,y) */
{
 mp_int a=Pget(L,1);
 mp_int b=Pget(L,2);
 lua_pushinteger(L,mp_int_compare(a,b));
 return 1;
}

static int Leq(lua_State *L)
{
 mp_int a=Pget(L,1);
 mp_int b=Pget(L,2);
 lua_pushboolean(L,mp_int_compare(a,b)==0);
 return 1;
}

static int Lle(lua_State *L)
{
 mp_int a=Pget(L,1);
 mp_int b=Pget(L,2);
 lua_pushboolean(L,mp_int_compare(a,b)<=0);
 return 1;
}

static int Llt(lua_State *L)
{
 mp_int a=Pget(L,1);
 mp_int b=Pget(L,2);
 lua_pushboolean(L,mp_int_compare(a,b)<0);
 return 1;
}

static int Liszero(lua_State *L)		/** iszero(x) */
{
 mp_int a=Pget(L,1);
 lua_pushboolean(L,mp_int_compare_zero(a)==0);
 return 1;
}

static int Liseven(lua_State *L)		/** iseven(x) */
{
 mp_int a=Pget(L,1);
 lua_pushboolean(L,mp_int_is_even(a));
 return 1;
}

static int Lisodd(lua_State *L)			/** isodd(x) */
{
 mp_int a=Pget(L,1);
 lua_pushboolean(L,mp_int_is_odd(a));
 return 1;
}

static int Lneg(lua_State *L)			/** neg(x) */
{
 return Pdo1(L,mp_int_neg);
}

static int Labs(lua_State *L)			/** abs(x) */
{
 return Pdo1(L,mp_int_abs);
}

static int Lsqr(lua_State *L)			/** sqr(x) */
{
 return Pdo1(L,mp_int_sqr);
}

static int Lsqrt(lua_State *L)			/** sqrt(x) */
{
 mp_int a=Pget(L,1);
 mp_int c=Pnew(L);
 return report(L,mp_int_sqrt(a,c),1);
}

static int Lroot(lua_State *L)			/** root(x,n) */
{
 mp_int a=Pget(L,1);
 mp_small n=luaL_optinteger(L,2,2);
 mp_int c=Pnew(L);
 return report(L,mp_int_root(a,n,c),1);
}

static int Pshift(lua_State *L, int d)	
{
 mp_int a=Pget(L,1);
 mp_small n=d*luaL_optinteger(L,2,2);
 mp_int c=Pnew(L);
 mp_int r=NULL;
 mp_result rc= (n>=0) ?  mp_int_mul_pow2(a,n,c) : mp_int_div_pow2(a,-n,c,r);
 return report(L,rc,1);
}

static int Lshl(lua_State *L)			/** shift(x,n) */
{
 return Pshift(L,1);
}

static int Lshr(lua_State *L)
{
 return Pshift(L,-1);
}

static int Ladd(lua_State *L)			/** add(x,y) */
{
 return Pdo2(L,mp_int_add);
}

static int Lsub(lua_State *L)			/** sub(x,y) */
{
 return Pdo2(L,mp_int_sub);
}

static int Lmul(lua_State *L)			/** mul(x,y) */
{
 return Pdo2(L,mp_int_mul);
}

static int Ldiv(lua_State *L)			/** div(x,y) */
{
 mp_int a=Pget(L,1);
 mp_int b=Pget(L,2);
 mp_int q=Pnew(L);
 mp_int r=NULL;
 return report(L,mp_int_div(a,b,q,r),1);
}

static int Lpow(lua_State *L)			/** pow(x,y) */
{
 return Pdo2(L,mp_int_expt_full);
}

static int Lmod(lua_State *L)			/** mod(x,y) */
{
 return Pdo2(L,mp_int_mod);
}

static int Lquotrem(lua_State *L)		/** quotrem(x,y) */
{
 mp_int a=Pget(L,1);
 mp_int b=Pget(L,2);
 mp_int q=Pnew(L);
 mp_int r=Pnew(L);
 return report(L,mp_int_div(a,b,q,r),2);
}

static int Lpowmod(lua_State *L)		/** powmod(x,y,m) */
{
 mp_int a=Pget(L,1);
 mp_int k=Pget(L,2);
 mp_int m=Pget(L,3);
 mp_int c=Pnew(L);
 return report(L,mp_int_exptmod(a,k,m,c),1);
}

static int Linvmod(lua_State *L)		/** invmod(x,m) */
{
 return Pdo2(L,mp_int_invmod);
}

static int Lgcd(lua_State *L)			/** gcd(x,y) */
{
 return Pdo2(L,mp_int_gcd);
}

static int Llcm(lua_State *L)			/** lcm(x,y) */
{
 return Pdo2(L,mp_int_lcm);
}

static int Legcd(lua_State *L)			/** egcd(x,y) */
{
 mp_int a=Pget(L,1);
 mp_int b=Pget(L,2);
 mp_int c=Pnew(L);
 mp_int x=Pnew(L);
 mp_int y=Pnew(L);
 return report(L,mp_int_egcd(a,b,c,x,y),3);
}

static int Lgc(lua_State *L)
{
 mp_int x=Pget(L,1);
 mp_int_clear(x);
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
	{ "__idiv",	Ldiv	},		/** __idiv(x,y) */
	{ "__le",	Lle	},		/** __le(x,y) */
	{ "__lt",	Llt	},		/** __lt(x,y) */
	{ "__mod",	Lmod	},		/** __mod(x,y) */
	{ "__mul",	Lmul	},		/** __mul(x,y) */
	{ "__pow",	Lpow	},		/** __pow(x,y) */
	{ "__shl",	Lshl	},		/** __shl(x,n) */
	{ "__shr",	Lshr	},		/** __shr(x,n) */
	{ "__sub",	Lsub	},		/** __sub(x,y) */
	{ "__tostring",	Ltostring},		/** __tostring(x) */
	{ "__unm",	Lneg	},		/** __unm(x) */
	{ "abs",	Labs	},
	{ "add",	Ladd	},
	{ "bits",	Lbits	},
	{ "compare",	Lcompare},
	{ "div",	Ldiv	},
	{ "egcd",	Legcd	},
	{ "gcd",	Lgcd	},
	{ "invmod",	Linvmod	},
	{ "iseven",	Liseven	},
	{ "isodd",	Lisodd	},
	{ "iszero",	Liszero	},
	{ "lcm",	Llcm	},
	{ "mod",	Lmod	},
	{ "mul",	Lmul	},
	{ "neg",	Lneg	},
	{ "new",	Lnew	},
	{ "pow",	Lpow	},
	{ "powmod",	Lpowmod	},
	{ "quotrem",	Lquotrem},
	{ "root",	Lroot	},
	{ "shift",	Lshl	},
	{ "sqr",	Lsqr	},
	{ "sqrt",	Lsqrt	},
	{ "sub",	Lsub	},
	{ "text",	Ltext	},
	{ "tonumber",	Ltonumber},
	{ "tostring",	Ltostring},
	{ "totext",	Ltotext	},
	{ NULL,		NULL	}
};

LUALIB_API int luaopen_imath(lua_State *L)
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
