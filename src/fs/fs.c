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

/***************************************************************************@@@
# File System

`fs` is a File System module. It provides functions to handle files and directory in a portable way.

```lua
local fs = require "fs"
```

## Core module (C)
@@@*/

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
#include <libgen.h>
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

/*@@@
```lua
fs.getcwd()
```
returns the current working directory.
@@@*/

static int fs_getcwd(lua_State *L)
{
    char path[FS_PATHSIZE+1];
    lua_pushstring(L, getcwd(path, FS_PATHSIZE));
    return 1;
}

/*@@@
```lua
fs.chdir(path)
```
changes the current directory to `path`.
@@@*/

static int fs_chdir(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    return bl_pushresult(L, chdir(path) == 0, path);
}

/*@@@
```lua
fs.dir([path])
```
returns the list of files and directories in
`path` (the default path is the current directory).
@@@*/

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

/*@@@
```lua
fs.glob(pattern)
```
returns the list of path names matching a pattern.

*Note*: not implemented on Windows.
@@@*/

#ifdef _WIN32

/* no glob function */
/* TODO: implement glob in Lua */

static int fs_glob(lua_State *L)
{
    return bl_pusherror(L, "glob: not implemented on Windows");
}

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

/*@@@
```lua
fs.remove(name)
```
deletes the file `name`.
@@@*/

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

/*@@@
```lua
fs.rename(old_name, new_name)
```
renames the file `old_name` to `new_name`.
@@@*/

static int fs_rename(lua_State *L)
{
    const char *fromname = luaL_checkstring(L, 1);
    const char *toname = luaL_checkstring(L, 2);
    return bl_pushresult(L, rename(fromname, toname) == 0, fromname);
}

/*@@@
```lua
fs.copy(source_name, target_name)
```
copies file `source_name` to `target_name`.
The attributes and times are preserved.
@@@*/

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

/*@@@
```lua
fs.mkdir(path)
```
creates a new directory `path`.
@@@*/

static int fs_mkdir(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
#ifdef _WIN32
    return bl_pushresult(L, mkdir(path) == 0, path);
#else
    return bl_pushresult(L, mkdir(path, 0755) == 0, path);
#endif
}

/*@@@
```lua
fs.stat(name)
```
reads attributes of the file `name`. Attributes are:

- `name`: name
- `type`: `"file"` or `"directory"`
- `size`: size in bytes
- `mtime`, `atime`, `ctime`: modification, access and creation times.
- `mode`: file permissions
- `uR`, `uW`, `uX`: user Read/Write/eXecute permissions
- `gR`, `gW`, `gX`: group Read/Write/eXecute permissions
- `oR`, `oW`, `oX`: other Read/Write/eXecute permissions
- `aR`, `aW`, `aX`: anybody Read/Write/eXecute permissions
@@@*/

static inline void set_string(lua_State *L, const char *name, const char *val)
{
    lua_pushstring(L, val);
    lua_setfield(L, -2, name);
}

static inline void set_integer(lua_State *L, const char *name, lua_Integer val)
{
    lua_pushinteger(L, val);
    lua_setfield(L, -2, name);
}

static inline void set_boolean(lua_State *L, const char *name, bool val)
{
    lua_pushboolean(L, val);
    lua_setfield(L, -2, name);
}

static int fs_stat(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    struct stat buf;
    if (stat(path, &buf)==0)
    {
        lua_newtable(L); /* stat */
        set_string(L, "name", path);
        set_integer(L, "size", buf.st_size);
        set_integer(L, "mtime", buf.st_mtime);
        set_integer(L, "atime", buf.st_atime);
        set_integer(L, "ctime", buf.st_ctime);
        set_string(L, "type", S_ISDIR(buf.st_mode)?"directory":S_ISREG(buf.st_mode)?"file":"unknown");
        set_integer(L, "mode", buf.st_mode);
        set_boolean(L, "uR", buf.st_mode & S_IRUSR);
        set_boolean(L, "uW", buf.st_mode & S_IWUSR);
        set_boolean(L, "uX", buf.st_mode & S_IXUSR);
        set_boolean(L, "gR", buf.st_mode & S_IRGRP);
        set_boolean(L, "gW", buf.st_mode & S_IWGRP);
        set_boolean(L, "gX", buf.st_mode & S_IXGRP);
        set_boolean(L, "oR", buf.st_mode & S_IROTH);
        set_boolean(L, "oW", buf.st_mode & S_IWOTH);
        set_boolean(L, "oX", buf.st_mode & S_IXOTH);
        return 1;
    }
    else
    {
        return bl_pushresult(L, 0, path);
    }
}

/*@@@
```lua
fs.inode(name)
```
reads device and inode attributes of the file `name`.
Attributes are:

- `dev`, `ino`: device and inode numbers
@@@*/

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
        return (ino_t)0;
    if (access(path, F_OK)) /* path does not exist */
        return (ino_t)(-1);
    /* obtain handle to "path"; FILE_FLAG_BACKUP_SEMANTICS is used to open directories */
    hFile = CreateFile(path, 0, 0, NULL, OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS | FILE_ATTRIBUTE_READONLY,
            NULL);
    if (hFile == INVALID_HANDLE_VALUE) /* file cannot be opened */
        return (ino_t)0;
    ZeroMemory(&FileInformation, sizeof(FileInformation));
    if (!GetFileInformationByHandle(hFile, &FileInformation)) { /* cannot obtain FileInformation */
        CloseHandle(hFile);
        return (ino_t)0;
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
        lua_newtable(L); /* stat */
        set_integer(L, "dev", (lua_Integer)buf.st_dev);
#ifdef _WIN32
        set_integer(L, "ino", (lua_Integer)getino(path));
#else
        set_integer(L, "ino", (lua_Integer)buf.st_ino);
#endif
        return 1;
    }
    else
    {
        return bl_pushresult(L, 0, path);
    }
}

/*@@@
```lua
fs.chmod(name, other_file_name)
```
sets file `name` permissions as
file `other_file_name` (string containing the name of another file).

```lua
fs.chmod(name, bit1, ..., bitn)
```
sets file `name` permissions as
`bit1` or ... or `bitn` (integers).
@@@*/

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

/*@@@
```lua
fs.touch(name)
```
sets the access time and the modification time of
file `name` with the current time.

```lua
fs.touch(name, number)
```
sets the access time and the modification
time of file `name` with `number`.

```lua
fs.touch(name, other_name)
```
sets the access time and the
modification time of file `name` with the times of file `other_name`.
@@@*/
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

/*@@@
```lua
fs.basename(path)
```
return the last component of path.
@@@*/

static int fs_basename(lua_State *L)
{
    char *path = safe_strdup(luaL_checkstring(L, 1));
    lua_pushstring(L, basename(path));
    free(path);
    return 1;
}

/*@@@
```lua
fs.dirname(path)
```
return all but the last component of path.
@@@*/

static int fs_dirname(lua_State *L)
{
    char *path = safe_strdup(luaL_checkstring(L, 1));
    lua_pushstring(L, dirname(path));
    free(path);
    return 1;
}

/*@@@
```lua
fs.realpath(path)
```
return the resolved path name of path.
@@@*/

static int fs_realpath(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
#ifdef _WIN32
    char real[FS_PATHSIZE+1];
    GetFullPathNameA(path, sizeof(real), real, NULL);
    lua_pushstring(L, real);
#else
    char *real = realpath(path, NULL);
    lua_pushstring(L, real);
    free(real);
#endif
    return 1;
}

/*@@@
```lua
fs.absname(path)
```
return the absolute path name of path.
@@@*/

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
    {"realpath",    fs_realpath},
    {"getcwd",      fs_getcwd},
    {"chdir",       fs_chdir},
    {"dir",         fs_dir},
    {"glob",        fs_glob},
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

/*@@@
```lua
fs.sep
```
is the directory separator.

```lua
fs.uR, fs.uW, fs.uX
fs.gR, fs.gW, fs.gX
fs.oR, fs.oW, fs.oX
fs.aR, fs.aW, fs.aX
```
are the User/Group/Other/All Read/Write/eXecute mask for `fs.chmod`.
@@@*/

LUAMOD_API int luaopen_fs(lua_State *L)
{
    luaL_newlib(L, fslib);
    /* File separator */
    set_string(L, "sep", LUA_DIRSEP);
    /* File permission bits */
    set_integer(L, "uR", S_IRUSR);
    set_integer(L, "uW", S_IWUSR);
    set_integer(L, "uX", S_IXUSR);
    set_integer(L, "aR", S_IRUSR|S_IRGRP|S_IROTH);
    set_integer(L, "aW", S_IWUSR|S_IWGRP|S_IWOTH);
    set_integer(L, "aX", S_IXUSR|S_IXGRP|S_IXOTH);
    set_integer(L, "gR", S_IRGRP);
    set_integer(L, "gW", S_IWGRP);
    set_integer(L, "gX", S_IXGRP);
    set_integer(L, "oR", S_IROTH);
    set_integer(L, "oW", S_IWOTH);
    set_integer(L, "oX", S_IXOTH);
    return 1;
}
