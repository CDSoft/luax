/*
* lmathx.c
* C99 math functions for Lua
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 04 Sep 2026 08:21:11
* This code is hereby placed in the public domain and also under the MIT license
*/

#define _GNU_SOURCE 1
#include <math.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "mycompat.h"

#ifndef l_mathop
#define l_mathop(op)	op
#endif

#define MYNAME		"mathx"
#define MYVERSION	MYNAME " library for " LUA_VERSION " / Sep 2026"

#define A(i)	luaL_checknumber(L,i)

#undef PI
#define PI		l_mathop(3.14159265358979323846264338327950288419716)
#define ONEDEGINRAD	l_mathop(0.01745329251994329576923690768488612713442)
#define ONERADINDEG	l_mathop(57.2957795130823208767981548141051703324054)
#define deg(x)		((x)*ONERADINDEG)
#define rad(x)		((x)*ONEDEGINRAD)

static int Lfmax(lua_State *L)			/** fmax */
{
 int i,n=lua_gettop(L);
 lua_Number m=A(1);
 for (i=2; i<=n; i++) m=fmax(m,A(i));
 lua_pushnumber(L,m);
 return 1;
}

static int Lfmin(lua_State *L)			/** fmin */
{
 int i,n=lua_gettop(L);
 lua_Number m=A(1);
 for (i=2; i<=n; i++) m=fmin(m,A(i));
 lua_pushnumber(L,m);
 return 1;
}

static int Lfpclassify(lua_State *L)		/** fpclassify */
{
 switch (fpclassify(A(1)))
 {
  case FP_INFINITE:	lua_pushliteral(L,"inf");	break;
  case FP_NAN:		lua_pushliteral(L,"nan");	break;
  case FP_NORMAL:	lua_pushliteral(L,"normal");	break;
  case FP_SUBNORMAL:	lua_pushliteral(L,"subnormal");	break;
  case FP_ZERO:		lua_pushliteral(L,"zero");	break;
 }
 return 1;
}

static int Lfrexp (lua_State *L)		/** frexp */
{
  lua_Number x=A(1);
  int e;
  lua_pushnumber(L,l_mathop(frexp)(x,&e));
  lua_pushinteger(L,e);
  return 2;
}

static int Lldexp (lua_State *L)		/** ldexp */
{
  lua_Number x=A(1);
  int e=(int)luaL_checkinteger(L,2);
  lua_pushnumber(L,l_mathop(ldexp)(x,e));
  return 1;
}

static int Lmodf (lua_State *L)			/** modf */
{
  lua_Number i;
  lua_Number f=l_mathop(modf)(A(1),&i);
  lua_pushnumber(L,i);
  lua_pushnumber(L,f);
  return 2;
}

static int Labs(lua_State *L)			/** abs */
{
 lua_pushnumber(L,l_mathop(fabs)(A(1)));
 return 1;
}

static int Lacos(lua_State *L)			/** acos */
{
 lua_pushnumber(L,l_mathop(acos)(A(1)));
 return 1;
}

static int Lacosh(lua_State *L)			/** acosh */
{
 lua_pushnumber(L,l_mathop(acosh)(A(1)));
 return 1;
}

static int Lasin(lua_State *L)			/** asin */
{
 lua_pushnumber(L,l_mathop(asin)(A(1)));
 return 1;
}

static int Lasinh(lua_State *L)			/** asinh */
{
 lua_pushnumber(L,l_mathop(asinh)(A(1)));
 return 1;
}

static int Latan(lua_State *L)			/** atan */
{
 lua_pushnumber(L,l_mathop(atan)(A(1)));
 return 1;
}

static int Latan2(lua_State *L)			/** atan2 */
{
 lua_pushnumber(L,l_mathop(atan2)(A(1),A(2)));
 return 1;
}

static int Latanh(lua_State *L)			/** atanh */
{
 lua_pushnumber(L,l_mathop(atanh)(A(1)));
 return 1;
}

static int Lcbrt(lua_State *L)			/** cbrt */
{
 lua_pushnumber(L,l_mathop(cbrt)(A(1)));
 return 1;
}

static int Lceil(lua_State *L)			/** ceil */
{
 lua_pushnumber(L,l_mathop(ceil)(A(1)));
 return 1;
}

static int Lcopysign(lua_State *L)		/** copysign */
{
 lua_pushnumber(L,l_mathop(copysign)(A(1),A(2)));
 return 1;
}

static int Lcos(lua_State *L)			/** cos */
{
 lua_pushnumber(L,l_mathop(cos)(A(1)));
 return 1;
}

static int Lcosh(lua_State *L)			/** cosh */
{
 lua_pushnumber(L,l_mathop(cosh)(A(1)));
 return 1;
}

static int Ldeg(lua_State *L)			/** deg */
{
 lua_pushnumber(L,deg(A(1)));
 return 1;
}

static int Lerf(lua_State *L)			/** erf */
{
 lua_pushnumber(L,l_mathop(erf)(A(1)));
 return 1;
}

static int Lerfc(lua_State *L)			/** erfc */
{
 lua_pushnumber(L,l_mathop(erfc)(A(1)));
 return 1;
}

static int Lexp(lua_State *L)			/** exp */
{
 lua_pushnumber(L,l_mathop(exp)(A(1)));
 return 1;
}

static int Lexp2(lua_State *L)			/** exp2 */
{
 lua_pushnumber(L,l_mathop(exp2)(A(1)));
 return 1;
}

static int Lexpm1(lua_State *L)			/** expm1 */
{
 lua_pushnumber(L,l_mathop(expm1)(A(1)));
 return 1;
}

static int Lfdim(lua_State *L)			/** fdim */
{
 lua_pushnumber(L,l_mathop(fdim)(A(1),A(2)));
 return 1;
}

static int Lfloor(lua_State *L)			/** floor */
{
 lua_pushnumber(L,l_mathop(floor)(A(1)));
 return 1;
}

static int Lfma(lua_State *L)			/** fma */
{
 lua_pushnumber(L,l_mathop(fma)(A(1),A(2),A(3)));
 return 1;
}

static int Lfmod(lua_State *L)			/** fmod */
{
 lua_pushnumber(L,l_mathop(fmod)(A(1),A(2)));
 return 1;
}

static int Lgamma(lua_State *L)			/** gamma */
{
 lua_pushnumber(L,l_mathop(tgamma)(A(1)));
 return 1;
}

static int Lhypot(lua_State *L)			/** hypot */
{
 lua_pushnumber(L,l_mathop(hypot)(A(1),A(2)));
 return 1;
}

static int Lilogb(lua_State *L)			/** ilogb */
{
 lua_pushinteger(L,l_mathop(ilogb)(A(1)));
 return 1;
}

static int Lisfinite(lua_State *L)		/** isfinite */
{
 lua_pushboolean(L,isfinite(A(1)));
 return 1;
}

static int Lisinf(lua_State *L)			/** isinf */
{
 lua_pushboolean(L,isinf(A(1)));
 return 1;
}

static int Lisnan(lua_State *L)			/** isnan */
{
 lua_pushboolean(L,isnan(A(1)));
 return 1;
}

static int Lisnormal(lua_State *L)		/** isnormal */
{
 lua_pushboolean(L,isnormal(A(1)));
 return 1;
}

static int Llgamma(lua_State *L)		/** lgamma */
{
 lua_pushnumber(L,l_mathop(lgamma)(A(1)));
 return 1;
}

static int Llog(lua_State *L)			/** log */
{
 lua_pushnumber(L,l_mathop(log)(A(1)));
 return 1;
}

static int Llog10(lua_State *L)			/** log10 */
{
 lua_pushnumber(L,l_mathop(log10)(A(1)));
 return 1;
}

static int Llog1p(lua_State *L)			/** log1p */
{
 lua_pushnumber(L,l_mathop(log1p)(A(1)));
 return 1;
}

static int Llog2(lua_State *L)			/** log2 */
{
 lua_pushnumber(L,l_mathop(log2)(A(1)));
 return 1;
}

#if 0
static int Llogb(lua_State *L)			/** logb */
{
 lua_pushnumber(L,l_mathop(logb)(A(1)));
 return 1;
}
#endif

static int Lnearbyint(lua_State *L)		/** nearbyint */
{
 lua_pushnumber(L,l_mathop(nearbyint)(A(1)));
 return 1;
}

static int Lnextafter(lua_State *L)		/** nextafter */
{
 lua_pushnumber(L,l_mathop(nextafter)(A(1),A(2)));
 return 1;
}

static int Lpow(lua_State *L)			/** pow */
{
 lua_pushnumber(L,l_mathop(pow)(A(1),A(2)));
 return 1;
}

static int Lrad(lua_State *L)			/** rad */
{
 lua_pushnumber(L,rad(A(1)));
 return 1;
}

static int Lremainder(lua_State *L)		/** remainder */
{
 lua_pushnumber(L,l_mathop(remainder)(A(1),A(2)));
 return 1;
}

static int Lremquo(lua_State *L)		/** remquo */
{
 int q;
 lua_pushnumber(L,l_mathop(remquo)(A(1),A(2),&q));
 lua_pushnumber(L,q);
 return 2;
}

static int Lrint(lua_State *L)			/** rint */
{
 lua_pushnumber(L,l_mathop(rint)(A(1)));
 return 1;
}

static int Lround(lua_State *L)			/** round */
{
 lua_pushnumber(L,l_mathop(round)(A(1)));
 return 1;
}

static int Lscalbn(lua_State *L)		/** scalbn */
{
 lua_pushnumber(L,l_mathop(scalbn)(A(1),A(2)));
 return 1;
}

static int Lsignbit(lua_State *L)		/** signbit */
{
 lua_pushboolean(L,signbit(A(1)));
 return 1;
}

static int Lsin(lua_State *L)			/** sin */
{
 lua_pushnumber(L,l_mathop(sin)(A(1)));
 return 1;
}

static int Lsinh(lua_State *L)			/** sinh */
{
 lua_pushnumber(L,l_mathop(sinh)(A(1)));
 return 1;
}

static int Lsqrt(lua_State *L)			/** sqrt */
{
 lua_pushnumber(L,l_mathop(sqrt)(A(1)));
 return 1;
}

static int Ltan(lua_State *L)			/** tan */
{
 lua_pushnumber(L,l_mathop(tan)(A(1)));
 return 1;
}

static int Ltanh(lua_State *L)			/** tanh */
{
 lua_pushnumber(L,l_mathop(tanh)(A(1)));
 return 1;
}

static int Ltrunc(lua_State *L)			/** trunc */
{
 lua_pushnumber(L,l_mathop(trunc)(A(1)));
 return 1;
}

static const luaL_Reg R[] =
{
	{ "abs",	Labs },
	{ "acos",	Lacos },
	{ "acosh",	Lacosh },
	{ "asin",	Lasin },
	{ "asinh",	Lasinh },
	{ "atan",	Latan },
	{ "atan2",	Latan2 },
	{ "atanh",	Latanh },
	{ "cbrt",	Lcbrt },
	{ "ceil",	Lceil },
	{ "copysign",	Lcopysign },
	{ "cos",	Lcos },
	{ "cosh",	Lcosh },
	{ "deg",	Ldeg },
	{ "erf",	Lerf },
	{ "erfc",	Lerfc },
	{ "exp",	Lexp },
	{ "exp2",	Lexp2 },
	{ "expm1",	Lexpm1 },
	{ "fabs",	Labs },
	{ "fdim",	Lfdim },
	{ "floor",	Lfloor },
	{ "fma",	Lfma },
	{ "fmax",	Lfmax },
	{ "fmin",	Lfmin },
	{ "fmod",	Lfmod },
	{ "fpclassify",	Lfpclassify },
	{ "frexp",	Lfrexp },
	{ "gamma",	Lgamma },
	{ "hypot",	Lhypot },
	{ "ilogb",	Lilogb },
	{ "isfinite",	Lisfinite },
	{ "isinf",	Lisinf },
	{ "isnan",	Lisnan },
	{ "isnormal",	Lisnormal },
	{ "ldexp",	Lldexp },
	{ "lgamma",	Llgamma },
	{ "log",	Llog },
	{ "log10",	Llog10 },
	{ "log1p",	Llog1p },
	{ "log2",	Llog2 },
	{ "logb",	Lilogb },
	{ "modf",	Lmodf },
	{ "nearbyint",	Lnearbyint },
	{ "nextafter",	Lnextafter },
	{ "pow",	Lpow },
	{ "rad",	Lrad },
	{ "remainder",	Lremainder },
	{ "remquo",	Lremquo },
	{ "rint",	Lrint },
	{ "round",	Lround },
	{ "scalbn",	Lscalbn },
	{ "signbit",	Lsignbit },
	{ "sin",	Lsin },
	{ "sinh",	Lsinh },
	{ "sqrt",	Lsqrt },
	{ "tan",	Ltan },
	{ "tanh",	Ltanh },
	{ "tgamma",	Lgamma },		/** tgamma */
	{ "trunc",	Ltrunc },
	{ NULL,		NULL }
};

LUALIB_API int luaopen_mathx(lua_State *L)
{
 luaL_newlib(L,R);
 lua_pushliteral(L,"version");			/** version */
 lua_pushliteral(L,MYVERSION);
 lua_settable(L,-3);
 lua_pushnumber(L,INFINITY);	lua_setfield(L,-2,"inf");
 lua_pushnumber(L,NAN);		lua_setfield(L,-2,"nan");
 lua_pushnumber(L,PI);		lua_setfield(L,-2,"pi");
 return 1;
}
