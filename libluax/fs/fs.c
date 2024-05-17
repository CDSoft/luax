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

#include "luaconf.h"
#include "F/F.h"
#include "tools.h"

#ifdef _WIN32
#include <shlwapi.h>
#include <stdint.h>
#include <windows.h>
#else
#include <fnmatch.h>
#include <glob.h>
#endif

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <libgen.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <utime.h>

#include "lua.h"
#include "lauxlib.h"

#ifndef BUFSIZE
#define BUFSIZE (8*1024)
#endif

/*@@@
```lua
fs.getcwd()
```
returns the current working directory.
@@@*/

static int fs_getcwd(lua_State *L)
{
    char path[PATH_MAX];
    lua_pushstring(L, getcwd(path, sizeof(path)));
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
    return luax_push_result_or_errno(L, chdir(path) == 0, path);
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
        return luax_pusherror(L, "bad argument #1 to dir (none, nil or string expected)");
    }
    DIR *dir = opendir(path);
    if (dir)
    {
        lua_newtable(L); /* file list */
        struct dirent *file;
        int n = 0;
        while ((file = readdir(dir)) != NULL)
        {
            if (strcmp(file->d_name, ".")==0) continue;
            if (strcmp(file->d_name, "..")==0) continue;
            lua_pushstring(L, file->d_name);
            lua_rawseti(L, -2, ++n);
        }
        closedir(dir);
        set_F_metatable(L);
        return 1;
    }
    else
    {
        return luax_push_result_or_errno(L, 0, path);
    }
}

#pragma GCC diagnostic ignored "-Wcomment"
/*@@@
```lua
fs.ls(path)
```
returns a list of file names.
`path` can be a directory name or a simple file pattern.
Patterns can contain jokers (`*` to match any character and `**` to search files recursively).

Examples:

- `fs.ls "src"`: list all files/directories in `src`
- `fs.ls "src/*.c"`: list all C files in `src`
- `fs.ls "src/**.c"`: list all C files in `src` and its subdirectories
@@@*/

#ifdef _WIN32

static inline int fnmatch(const char *pattern, const char *name, int flags __attribute__((unused)))
{
    return PathMatchSpecA(name, pattern) ? 0 : 1;
}

#endif

static void ls(lua_State *L, const char *dir, const char *base, bool dotted, bool recursive, int *size)
{
    const bool cwd = dir[0] == '.' && dir[1] == '\0';
    DIR *d = opendir(dir);
    if (d) {
        struct dirent *file;
        while ((file = readdir(d)) != NULL) {
            if (strcmp(file->d_name, ".") == 0) continue;
            if (strcmp(file->d_name, "..") == 0) continue;
            if (file->d_name[0] == '.' && !dotted) continue;
            if (fnmatch(base, file->d_name, 0) == 0) {
                if (cwd) {
                    lua_pushstring(L, file->d_name);
                } else {
                    luaL_Buffer B;
                    luaL_buffinit(L, &B);
                    luaL_addstring(&B, dir);
                    luaL_addstring(&B, LUA_DIRSEP);
                    luaL_addstring(&B, file->d_name);
                    luaL_pushresult(&B);
                }
                (*size)++;
                lua_rawseti(L, -2, *size);
            }
            if (recursive) {
                bool is_dir;
#ifdef _WIN32
                struct stat buf;
                is_dir = stat(file->d_name, &buf) == 0 && S_ISDIR(buf.st_mode);
#else
                switch (file->d_type) {
                    case DT_DIR:
                        is_dir = true;
                        break;
                    case DT_LNK:
                    {
                        struct stat buf;
                        is_dir = stat(file->d_name, &buf) == 0 && S_ISDIR(buf.st_mode);
                        break;
                    }
                    default:
                        is_dir = false;
                        break;
                }
#endif
                if (is_dir) {
                    if (cwd) {
                        ls(L, file->d_name, base, dotted, recursive, size);
                    } else {
                        char subdir[PATH_MAX];
                        strncpy(subdir, dir, sizeof(subdir));
                        strncat(subdir, LUA_DIRSEP, sizeof(subdir)-1);
                        strncat(subdir, file->d_name, sizeof(subdir)-1);
                        ls(L, subdir, base, dotted, recursive, size);
                    }
                }
            }
        }
        closedir(d);
    }
}

static int fs_ls(lua_State *L)
{
    const char *path;
    if (lua_isstring(L, 1)) {
        path = luaL_checkstring(L, 1);
    } else if (lua_isnoneornil(L, 1)) {
        path = "."LUA_DIRSEP"*";
    } else {
        return luax_pusherror(L, "bad argument #1 to ls (none, nil or string expected)");
    }

    bool dotted;
    if (lua_isboolean(L, 2)) {
        dotted = lua_toboolean(L, 2);
    } else if (lua_isnoneornil(L, 2)) {
        dotted = false;
    } else {
        return luax_pusherror(L, "bad argument #2 to ls (none, nil or boolean expected)");
    }

    char tmp[PATH_MAX];

    char dir[PATH_MAX];
    strncpy(tmp, path, sizeof(tmp));
    strncpy(dir, dirname(tmp), sizeof(dir));

    char base[PATH_MAX];
    strncpy(tmp, path, sizeof(tmp));
    strncpy(base, basename(tmp), sizeof(base));
    const size_t base_len = strlen(base);

    if (strncmp(base, ".", base_len+1) == 0) {
        strncpy(base, "*", base_len+1);
    }

    bool recursive = false;
    for (int i = 0; i < (int)base_len-1; i++) {
        if (base[i] == '*' && base[i+1] == '*') {
            recursive = true;
            break;
        }
    }

    bool pattern = false;
    for (int i = 0; i < (int)base_len; i++) {
        if (base[i] == '*' || base[i] == '?') {
            pattern = true;
            break;
        }
    }

    if (!pattern) {
        /* no pattern in base => list all files in dir/base */
        strncat(dir, LUA_DIRSEP, sizeof(tmp)-1);
        strncat(dir, base, sizeof(tmp)-1);
        strncpy(base, "*", base_len+1);
    }

    lua_newtable(L);                        /* stack: list */
    int size = 0;
    ls(L, dir, base, dotted, recursive, &size);
    lua_getglobal(L, "table");              /* stack: list "table" */
    lua_getfield(L, -1, "sort");            /* stack: list "table" table.sort */
    lua_remove(L, -2);                      /* stack: list table.sort */
    lua_pushvalue(L, -2);                   /* stack: list table.sort list */
    lua_call(L, 1, 0);                      /* stack: list */
    set_F_metatable(L);
    return 1;
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
    return luax_pusherror(L, "glob: not implemented on Windows");
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
        return luax_pusherror(L, "bad argument #1 to pattern (none, nil or string expected)");
    }
    glob_t globres;
    const int r = glob(pattern, 0, NULL, &globres);
    if (r == 0 || r == GLOB_NOMATCH)
    {
        lua_newtable(L); /* file list */
        for (unsigned int i=1; i<=globres.gl_pathc; i++)
        {
            lua_pushstring(L, globres.gl_pathv[i-1]);
            lua_rawseti(L, -2, i);
        }
        globfree(&globres);
        set_F_metatable(L);
        return 1;
    }
    else
    {
        return luax_push_result_or_errno(L, 0, pattern);
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
        return luax_push_result_or_errno(L, rmdir(filename) == 0, filename);
    }
#endif
    return luax_push_result_or_errno(L, remove(filename) == 0, filename);
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
    return luax_push_result_or_errno(L, rename(fromname, toname) == 0, fromname);
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
    FILE *from = fopen(fromname, "rb");
    if (!from) return luax_push_result_or_errno(L, 0, fromname);
    FILE *to = fopen(toname, "wb");
    if (!to)
    {
        const int _en = errno;
        fclose(from);
        errno = _en;
        return luax_push_result_or_errno(L, 0, toname);
    }
    size_t n;
    char buffer[BUFSIZE];
    while ((n = fread(buffer, sizeof(char), sizeof(buffer), from)))
    {
        if (fwrite(buffer, sizeof(char), n, to) != n)
        {
            const int _en = errno;
            fclose(from);
            fclose(to);
            remove(toname);
            errno = _en;
            return luax_push_result_or_errno(L, 0, toname);
        }
    }
    if (ferror(from))
    {
        const int _en = errno;
        fclose(from);
        fclose(to);
        remove(toname);
        errno = _en;
        return luax_push_result_or_errno(L, 0, toname);
    }
    fclose(from);
    fclose(to);
    struct stat st;
    if (stat(fromname, &st) != 0) return luax_push_result_or_errno(L, 0, fromname);
    const bool time_ok = utime(toname, &(struct utimbuf){.actime=st.st_atime, .modtime=st.st_mtime}) == 0;
    const bool chmod_ok = chmod(toname, st.st_mode) == 0;
    return luax_push_result_or_errno(L, time_ok && chmod_ok, toname);
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
    return luax_push_result_or_errno(L, mkdir(path) == 0, path);
#else
    return luax_push_result_or_errno(L, mkdir(path, 0755) == 0, path);
#endif
}

/*@@@
```lua
fs.mkdirs(path)
```
creates a new directory `path` and its parent directories.
@@@*/

static bool mkdirs(const char *path)
{
    struct stat buf;
    if (stat(path, &buf)==0) {
        return true;
    }

    char path_dir[PATH_MAX];
    strncpy(path_dir, path, sizeof(path_dir));
    const char *dir = dirname(path_dir);

    if (!mkdirs(dir)) { return false; }

#ifdef _WIN32
    return mkdir(path) == 0;
#else
    return mkdir(path, 0755) == 0;
#endif
}

static int fs_mkdirs(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    return luax_push_result_or_errno(L, mkdirs(path), path);
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
        set_boolean(L, "aR", buf.st_mode & (S_IRUSR|S_IRGRP|S_IROTH));
        set_boolean(L, "aW", buf.st_mode & (S_IWUSR|S_IWGRP|S_IWOTH));
        set_boolean(L, "aX", buf.st_mode & (S_IXUSR|S_IXGRP|S_IXOTH));
        set_F_metatable(L);
        return 1;
    }
    else
    {
        return luax_push_result_or_errno(L, 0, path);
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
        return luax_push_result_or_errno(L, 0, path);
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
        if (stat(ref, &st) != 0) return luax_push_result_or_errno(L, 0, ref);
        mode = st.st_mode;
    }
    else
    {
        return luax_pusherror(L, "bad argument #2 to 'chmod' (number or string expected)");
    }
    return luax_push_result_or_errno(L, chmod(path, mode) == 0, path);
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
        if (stat(ref, &st) != 0) return luax_push_result_or_errno(L, 0, ref);
        t.actime = st.st_atime;
        t.modtime = st.st_mtime;
    }
    else
    {
        return luax_pusherror(L, "bad argument #2 to touch (none, nil, number or string expected)");
    }
    if (access(path, F_OK) != 0)
    {
        const int fd = open(path, O_CREAT, S_IRUSR | S_IWUSR);
        if (fd < 0) return luax_push_result_or_errno(L, 0, path);
        if (fd >= 0) close(fd);
    }
    return luax_push_result_or_errno(L, utime(path, &t) == 0, path);
}

/*@@@
```lua
fs.basename(path)
```
return the last component of path.
@@@*/

static int fs_basename(lua_State *L)
{
    char path[PATH_MAX];
    strncpy(path, luaL_checkstring(L, 1), sizeof(path));
    lua_pushstring(L, basename(path));
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
    char path[PATH_MAX];
    strncpy(path, luaL_checkstring(L, 1), sizeof(path));
    lua_pushstring(L, dirname(path));
    return 1;
}

/*@@@
```lua
fs.splitext(path)
```
return the name without the extension and the extension.
@@@*/

static int fs_splitext(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    const size_t len = (size_t)lua_rawlen(L, 1);
    for (size_t i = len-1; i > 0; i--)
    {
        if (path[i] == '.' && path[i-1] != '/' && path[i-1] != '\\')
        {
            lua_pushlstring(L, path, i);
            lua_pushlstring(L, &path[i], len-i);
            return 2;
        }
        if (path[i] == '/' || path[i] == '\\')
        {
            break;
        }
    }
    lua_pushlstring(L, path, len);
    lua_pushlstring(L, "", 0);
    return 2;
}

/*@@@
```lua
fs.ext(path)
```
return the extension of a filename.
@@@*/

static int fs_ext(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    const size_t len = (size_t)lua_rawlen(L, 1);
    for (size_t i = len-1; i > 0; i--)
    {
        if (path[i] == '.' && path[i-1] != '/' && path[i-1] != '\\')
        {
            lua_pushlstring(L, &path[i], len-i);
            return 1;
        }
        if (path[i] == '/' || path[i] == '\\')
        {
            break;
        }
    }
    lua_pushlstring(L, "", 0);
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
    char real[PATH_MAX];
#ifdef _WIN32
    const DWORD n = GetFullPathNameA(path, sizeof(real), real, NULL);
    if (n == 0) {
        return luax_pusherror(L, "GetFullPathNameA failure: %d", GetLastError());
    }
#else
    const char *name = realpath(path, real);
    if (name == NULL) {
        return luax_push_result_or_errno(L, false, path);
    }
#endif
    lua_pushstring(L, real);
    return 1;
}

/*@@@
```lua
fs.readlink(path)
```
return the content of a symbolic link.
@@@*/

static int fs_readlink(lua_State *L)
{
#ifdef _WIN32
    return luax_pusherror(L, "readlink not implemented");
#else
    const char *path = luaL_checkstring(L, 1);
    char dest[PATH_MAX];
    const ssize_t n = readlink(path, dest, sizeof(dest));
    if (n < 0)
    {
        return luax_pusherror(L, "readlink failure");
    }
    dest[n] = '\0';
    lua_pushstring(L, dest);
    return 1;
#endif
}

/*@@@
```lua
fs.absname(path)
```
return the absolute path name of path.
@@@*/

static int fs_absname(lua_State *L)
{
    char path[PATH_MAX];
    const char *name = luaL_checkstring(L, 1);
    if (  name[0] == '/' || name[0] == '\\'
       || (name[0] && name[1] == ':')
       )
    {
        /* already an absolute path */
        lua_pushstring(L, name);
        return 1;
    }
    if (getcwd(path, sizeof(path)) == NULL)
    {
        return luax_pusherror(L, "getcwd failure");
    }
    strncat(path, LUA_DIRSEP, sizeof(path)-strlen(path)-1);
    strncat(path, name, sizeof(path)-strlen(path)-1);
    lua_pushstring(L, path);
    return 1;
}

static const luaL_Reg fslib[] =
{
    {"basename",    fs_basename},
    {"dirname",     fs_dirname},
    {"splitext",    fs_splitext},
    {"ext",         fs_ext},
    {"absname",     fs_absname},
    {"realpath",    fs_realpath},
    {"readlink",    fs_readlink},
    {"getcwd",      fs_getcwd},
    {"chdir",       fs_chdir},
    {"dir",         fs_dir},
    {"ls",          fs_ls},
    {"glob",        fs_glob},
    {"remove",      fs_remove},
    {"rename",      fs_rename},
    {"mkdir",       fs_mkdir},
    {"mkdirs",      fs_mkdirs},
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
fs.path_sep
```
is the path separator in `$LUA_PATH`.

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
#ifdef _WIN32
    set_string(L, "path_sep", ";");
#else
    set_string(L, "path_sep", ":");
#endif
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
