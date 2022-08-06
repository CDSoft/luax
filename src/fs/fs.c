/* This file is part of luax.
 *
 * luax is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * luax is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about luax you can visit
 * http://cdelord.fr/luax
 */

#include "fs.h"

#include "tools.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <glob.h>
#endif

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <utime.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#define FS_PATHSIZE 1024
#define FS_BUFSIZE  (64*1024)

static int fs_getcwd(lua_State *L)
{
    char path[FS_PATHSIZE+1];
    lua_pushstring(L, getcwd(path, FS_PATHSIZE));
    return 1;
}

static int fs_chdir(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    return bl_pushresult(L, chdir(path) == 0, path);
}

static int fs_dir(lua_State *L)
{
    const char *path;
    if (lua_isstring(L, 1))
    {
        path = luaL_checkstring(L, 1);
    }
    else if (lua_isnoneornil(L, 1))
    {
        path = ".";
    }
    else
    {
        return bl_pusherror(L, "bad argument #1 to dir (none, nil or string expected)");
    }
    DIR *dir = opendir(path);
    struct dirent *file;
    int n = 0;
    if (dir)
    {
        lua_newtable(L); /* file list */
        while ((file = readdir(dir)))
        {
            if (strcmp(file->d_name, ".")==0) continue;
            if (strcmp(file->d_name, "..")==0) continue;
            lua_pushstring(L, file->d_name);
            lua_rawseti(L, -2, ++n);
        }
        closedir(dir);
        return 1;
    }
    else
    {
        return bl_pushresult(L, 0, path);
    }
}

#ifdef _WIN32

/* no glob function */
/* TODO: implement glob in Lua */

#else

static int fs_glob(lua_State *L)
{
    const char *pattern;
    if (lua_isstring(L, 1))
    {
        pattern = luaL_checkstring(L, 1);
    }
    else if (lua_isnoneornil(L, 1))
    {
        pattern = "*";
    }
    else
    {
        return bl_pusherror(L, "bad argument #1 to pattern (none, nil or string expected)");
    }
    glob_t globres;
    unsigned int i;
    int r = glob(pattern, 0, NULL, &globres);
    if (r == 0 || r == GLOB_NOMATCH)
    {
        lua_newtable(L); /* file list */
        for (i=1; i<=globres.gl_pathc; i++)
        {
            lua_pushstring(L, globres.gl_pathv[i-1]);
            lua_rawseti(L, -2, i);
        }
        globfree(&globres);
        return 1;
    }
    else
    {
        return bl_pushresult(L, 0, pattern);
    }
}

#endif

static int fs_remove(lua_State *L)
{
    const char *filename = luaL_checkstring(L, 1);
#ifdef _WIN32
    struct stat st;
    stat(filename, &st);
    if (S_ISDIR(st.st_mode))
    {
        return bl_pushresult(L, rmdir(filename) == 0, filename);
    }
#endif
    return bl_pushresult(L, remove(filename) == 0, filename);
}

static int fs_rename(lua_State *L)
{
    const char *fromname = luaL_checkstring(L, 1);
    const char *toname = luaL_checkstring(L, 2);
    return bl_pushresult(L, rename(fromname, toname) == 0, fromname);
}

static int fs_copy(lua_State *L)
{
    const char *fromname = luaL_checkstring(L, 1);
    const char *toname = luaL_checkstring(L, 2);
    int _en;
    FILE *from, *to;
    size_t n;
    char buffer[FS_BUFSIZE];
    struct stat st;
    struct utimbuf t;
    from = fopen(fromname, "rb");
    if (!from) return bl_pushresult(L, 0, fromname);
    to = fopen(toname, "wb");
    if (!to)
    {
        _en = errno;
        fclose(from);
        errno = _en;
        return bl_pushresult(L, 0, toname);
    }
    while ((n = fread(buffer, sizeof(char), FS_BUFSIZE, from)))
    {
        if (fwrite(buffer, sizeof(char), n, to) != n)
        {
            _en = errno;
            fclose(from);
            fclose(to);
            remove(toname);
            errno = _en;
            return bl_pushresult(L, 0, toname);
        }
    }
    if (ferror(from))
    {
        _en = errno;
        fclose(from);
        fclose(to);
        remove(toname);
        errno = _en;
        return bl_pushresult(L, 0, toname);
    }
    fclose(from);
    fclose(to);
    if (stat(fromname, &st) != 0) return bl_pushresult(L, 0, fromname);
    t.actime = st.st_atime;
    t.modtime = st.st_mtime;
    return bl_pushresult(L, 
        utime(toname, &t) == 0 && chmod(toname, st.st_mode) == 0,
        toname);
}

static int fs_mkdir(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
#ifdef _WIN32
    return bl_pushresult(L, mkdir(path) == 0, path);
#else
    return bl_pushresult(L, mkdir(path, 0755) == 0, path);
#endif
}

static int fs_stat(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    struct stat buf;
    if (stat(path, &buf)==0)
    {
#define STRING(VAL, ATTR) { lua_pushstring(L, VAL); lua_setfield(L, -2, ATTR); }
#define INTEGER(VAL, ATTR) { lua_pushinteger(L, VAL); lua_setfield(L, -2, ATTR); }
        lua_newtable(L); /* stat */
        STRING(path, "name")
        INTEGER(buf.st_size, "size")
        INTEGER(buf.st_mtime, "mtime")
        INTEGER(buf.st_atime, "atime")
        INTEGER(buf.st_ctime, "ctime")
        STRING(S_ISDIR(buf.st_mode)?"directory":S_ISREG(buf.st_mode)?"file":"unknown", "type")
        INTEGER(buf.st_mode, "mode")
#define PERMISSION(MASK, ATTR) { lua_pushboolean(L, buf.st_mode & MASK); lua_setfield(L, -2, ATTR); }
        PERMISSION(S_IRUSR, "uR")
        PERMISSION(S_IWUSR, "uW")
        PERMISSION(S_IXUSR, "uX")
#ifndef _WIN32
        PERMISSION(S_IRGRP, "gR")
        PERMISSION(S_IWGRP, "gW")
        PERMISSION(S_IXGRP, "gX")
        PERMISSION(S_IROTH, "oR")
        PERMISSION(S_IWOTH, "oW")
        PERMISSION(S_IXOTH, "oX")
#endif
#undef STRING
#undef INTEGER
#undef PERMISSION
        return 1;
    }
    else
    {
        return bl_pushresult(L, 0, path);
    }
}

#ifdef _WIN32

/* "inode" number for MS-Windows (http://gnuwin32.sourceforge.net/compile.html) */

static ino_t getino(const char *path)
{
    #define LODWORD(l) ((DWORD)((DWORDLONG)(l)))
    #define HIDWORD(l) ((DWORD)(((DWORDLONG)(l)>>32)&0xFFFFFFFF))
    #define MAKEDWORDLONG(a,b) ((DWORDLONG)(((DWORD)(a))|(((DWORDLONG)((DWORD)(b)))<<32)))
    #define INOSIZE (8*sizeof(ino_t))
    #define SEQNUMSIZE (16)

    BY_HANDLE_FILE_INFORMATION FileInformation;
    HANDLE hFile;
    uint64_t ino64, refnum;
    ino_t ino;
    if (!path || !*path) /* path = NULL */
        return 0;
    if (access(path, F_OK)) /* path does not exist */
        return -1;
    /* obtain handle to "path"; FILE_FLAG_BACKUP_SEMANTICS is used to open directories */
    hFile = CreateFile(path, 0, 0, NULL, OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS | FILE_ATTRIBUTE_READONLY,
            NULL);
    if (hFile == INVALID_HANDLE_VALUE) /* file cannot be opened */
        return 0;
    ZeroMemory(&FileInformation, sizeof(FileInformation));
    if (!GetFileInformationByHandle(hFile, &FileInformation)) { /* cannot obtain FileInformation */
        CloseHandle(hFile);
        return 0;
    }
    ino64 = (uint64_t)MAKEDWORDLONG(
        FileInformation.nFileIndexLow, FileInformation.nFileIndexHigh);
    refnum = ino64 & ((~(0ULL)) >> SEQNUMSIZE); /* strip sequence number */
    /* transform 64-bits ino into 16-bits by hashing */
    ino = (ino_t)(
            ( (LODWORD(refnum)) ^ ((LODWORD(refnum)) >> INOSIZE) )
        ^
            ( (HIDWORD(refnum)) ^ ((HIDWORD(refnum)) >> INOSIZE) )
        );
    CloseHandle(hFile);
    return ino;

    #undef LODWORD
    #undef HIDWORD
    #undef MAKEDWORDLONG
    #undef INOSIZE
    #undef SEQNUMSIZE
}
#endif

static int fs_inode(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    struct stat buf;
    if (stat(path, &buf)==0)
    {
#define INTEGER(VAL, ATTR) { lua_pushinteger(L, VAL); lua_setfield(L, -2, ATTR); }
        lua_newtable(L); /* stat */
        INTEGER((lua_Integer)buf.st_dev, "dev")
#ifdef _WIN32
        INTEGER((lua_Integer)getino(path), "ino")
#else
        INTEGER((lua_Integer)buf.st_ino, "ino")
#endif
#undef INTEGER
        return 1;
    }
    else
    {
        return bl_pushresult(L, 0, path);
    }
}

static int fs_chmod(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    mode_t mode;
    if (lua_type(L, 2) == LUA_TNUMBER)
    {
        mode = 0;
        for (int i=2; !lua_isnone(L, i); i++)
        {
            const lua_Number n = luaL_checknumber(L, i);
            mode |= (mode_t)n;
        }
    }
    else if (lua_type(L, 2) == LUA_TSTRING)
    {
        const char *ref = luaL_checkstring(L, 2);
        struct stat st;
        if (stat(ref, &st) != 0) return bl_pushresult(L, 0, ref);
        mode = st.st_mode;
    }
    else
    {
        return bl_pusherror(L, "bad argument #2 to 'chmod' (number or string expected)");
    }
    return bl_pushresult(L, chmod(path, mode) == 0, path);
}

static int fs_touch(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    struct utimbuf t;
    if (lua_isnoneornil(L, 2))
    {
        t.actime = t.modtime = time(NULL);
    }
    else if (lua_type(L, 2) == LUA_TNUMBER)
    {
        const lua_Number n = luaL_checknumber(L, 2);
        t.actime = t.modtime = (time_t)n;
    }
    else if (lua_type(L, 2) == LUA_TSTRING)
    {
        const char *ref = luaL_checkstring(L, 2);
        struct stat st;
        if (stat(ref, &st) != 0) return bl_pushresult(L, 0, ref);
        t.actime = st.st_atime;
        t.modtime = st.st_mtime;
    }
    else
    {
        return bl_pusherror(L, "bad argument #2 to touch (none, nil, number or string expected)");
    }
    if (access(path, F_OK) != 0)
    {
        int fd = open(path, O_CREAT, S_IRUSR | S_IWUSR);
        if (fd < 0) return bl_pushresult(L, 0, path);
        if (fd >= 0) close(fd);
    }
    return bl_pushresult(L, utime(path, &t) == 0, path);
}

static int fs_basename(lua_State *L)
{
    char path[FS_PATHSIZE+1];
    strncpy(path, luaL_checkstring(L, 1), FS_PATHSIZE);
    path[FS_PATHSIZE] = '\0';
    char *p = path;
    while (*p) p++;
    while (p>path && (*(p-1)=='/' || *(p-1)=='\\')) *--p = '\0';
    while (p>path && (*(p-1)!='/' && *(p-1)!='\\')) p--;
    lua_pushstring(L, p);
    return 1;
}

static int fs_dirname(lua_State *L)
{
    char path[FS_PATHSIZE+1];
    strncpy(path, luaL_checkstring(L, 1), FS_PATHSIZE);
    path[FS_PATHSIZE] = '\0';
    char *p = path;
    while (*p) p++;
    while (p>path && (*(p-1)=='/' || *(p-1)=='\\')) *--p = '\0';
    while (p>path && (*(p-1)!='/' && *(p-1)!='\\')) *--p = '\0';
    while (p>path && (*(p-1)=='/' || *(p-1)=='\\')) *--p = '\0';
    lua_pushstring(L, path);
    return 1;
}

static int fs_absname(lua_State *L)
{
    char path[FS_PATHSIZE+1];
    const char *name = luaL_checkstring(L, 1);
    if (  name[0] == '/' || name[0] == '\\'
       || (name[0] && name[1] == ':')
       )
    {
        /* already an absolute path */
        lua_pushstring(L, name);
        return 1;
    }
    if (getcwd(path, FS_PATHSIZE) == NULL)
    {
        bl_pusherror(L, "getcwd failure");
    }
    strncat(path, LUA_DIRSEP, FS_PATHSIZE-strlen(path));
    strncat(path, name, FS_PATHSIZE-strlen(path));
    lua_pushstring(L, path);
    return 1;
}

static const luaL_Reg fslib[] =
{
    {"basename",    fs_basename},
    {"dirname",     fs_dirname},
    {"absname",     fs_absname},
    {"getcwd",      fs_getcwd},
    {"chdir",       fs_chdir},
    {"dir",         fs_dir},
#ifdef _WIN32
    /* no glob function */
#else
    {"glob",        fs_glob},
#endif
    {"remove",      fs_remove},
    {"rename",      fs_rename},
    {"mkdir",       fs_mkdir},
    {"stat",        fs_stat},
    {"inode",       fs_inode},
    {"chmod",       fs_chmod},
    {"touch",       fs_touch},
    {"copy",        fs_copy},
    {NULL, NULL}
};

LUAMOD_API int luaopen_fs(lua_State *L)
{
    luaL_newlib(L, fslib);
#define STRING(NAME, VAL) lua_pushliteral(L, VAL); lua_setfield(L, -2, NAME)
#define INTEGER(NAME, VAL) lua_pushinteger(L, VAL); lua_setfield(L, -2, NAME)
    /* File separator */
    STRING("sep", LUA_DIRSEP);
    /* File permission bits */
    INTEGER("uR", S_IRUSR);
    INTEGER("uW", S_IWUSR);
    INTEGER("uX", S_IXUSR);
#ifdef _WIN32
    INTEGER("aR", S_IRUSR);
    INTEGER("aW", S_IWUSR);
    INTEGER("aX", S_IXUSR);
#else
    INTEGER("aR", S_IRUSR|S_IRGRP|S_IROTH);
    INTEGER("aW", S_IWUSR|S_IWGRP|S_IWOTH);
    INTEGER("aX", S_IXUSR|S_IXGRP|S_IXOTH);
    INTEGER("gR", S_IRGRP);
    INTEGER("gW", S_IWGRP);
    INTEGER("gX", S_IXGRP);
    INTEGER("oR", S_IROTH);
    INTEGER("oW", S_IWOTH);
    INTEGER("oX", S_IXOTH);
#endif
#undef STRING
#undef INTEGER
    return 1;
}
