/* @(#) pf_mem.h 98/01/26 1.3 */
#ifndef _pf_mem_h
#define _pf_mem_h

/***************************************************************
** Include file for PForth Fake Memory Allocator
**
** Author: Phil Burk
** Copyright 1994 3DO, Phil Burk, Larry Polansky, David Rosenboom
**
** Permission to use, copy, modify, and/or distribute this
** software for any purpose with or without fee is hereby granted.
**
** THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
** WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
** WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL
** THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
** CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING
** FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
** CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
** OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
***************************************************************/

#ifdef PF_NO_MALLOC

    #ifdef __cplusplus
    extern "C" {
    #endif

    void  pfInitMemoryAllocator( void );
    char *pfAllocMem( cell_t NumBytes );
    void  pfFreeMem( void *Mem );

    #define pfAllocSharedMem pfAllocMem
    #define pfFreeSharedMem pfFreeMem

    #ifdef __cplusplus
    }
    #endif

#else

    #include "pf_shmem.h"

    #ifdef PF_USER_MALLOC
/* Get user prototypes or macros from include file.
** API must match that defined above for the stubs.
*/
        #include PF_USER_MALLOC
    #else
        #include <stdlib.h>

        #define pfInitMemoryAllocator()

        static inline char *pfAllocMem( cell_t NumBytes )
        {
            return (char *) malloc( (size_t) NumBytes );
        }

        static inline void pfFreeMem( void *Mem )
        {
            free( Mem );
        }
    #endif

    static inline char *pfAllocSharedMem( cell_t NumBytes )
    {
        return (char *) shmem_malloc( (size_t) NumBytes );
    }

    static inline void pfFreeSharedMem( void *Mem )
    {
        shmem_free( Mem );
    }

#endif /* PF_NO_MALLOC */

#endif /* _pf_mem_h */
