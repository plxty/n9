#ifndef __BYTESWAP_H__
#define __BYTESWAP_H__

/* Prevent macOS uuid_t being introduced (and used) by OSByteOrder. */
#define _UUID_T
#define __GETHOSTUUID_H

/* https://github.com/sgan81/apfs-fuse/issues/6#issuecomment-363601678 */
#include <libkern/OSByteOrder.h>
#define bswap_16(x) OSSwapInt16(x)
#define bswap_32(x) OSSwapInt32(x)
#define bswap_64(x) OSSwapInt64(x)

/* https://git.musl-libc.org/cgit/musl/plain/src/string/strchrnul.c */
/* 39e2635b3064df1e2b15cb45d60c654238ad8f79 */
static inline char *strchrnul(const char *s, int c) {
  c = (unsigned char)c;
  if (!c)
    return (char *)s + strlen(s);

  for (; *s && *(unsigned char *)s != c; ++s)
    ;
  return (char *)s;
}

#endif
