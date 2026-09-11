/* @(#) pfcustom.c 98/01/26 1.3 */
#undef PF_USER_CUSTOM
#ifndef PF_USER_CUSTOM

/***************************************************************
** Call Custom Functions for pForth
**
** Create a file similar to this and compile it into pForth
** by setting -DPF_USER_CUSTOM="mycustom.c"
**
** Using this, you could, for example, call X11 from Forth.
** See "pf_cglue.c" for more information.
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
**
***************************************************************/


#include "pf_all.h"
#include "pf_shmem.h"

unsigned long wtime( void );
#include "pf_wtime.c"

static cell_t pf_shmem_put(cell_t dest, cell_t source, cell_t nelems, cell_t pe);
static cell_t pf_shmem_get(cell_t dest, cell_t source, cell_t nelems, cell_t pe);
static cell_t pf_shmem_put32(cell_t dest, cell_t source, cell_t nelems, cell_t pe);
static cell_t pf_shmem_get32(cell_t dest, cell_t source, cell_t nelems, cell_t pe);
static cell_t pf_shmem_global_exit(cell_t status);
static cell_t pf_shmem_barrier(cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync);
static cell_t pf_shmem_malloc(cell_t size);
static cell_t pf_shmem_free(cell_t addr);
static cell_t pf_shmem_ptr(cell_t addr, cell_t pe);
static cell_t pf_shmem_broadcast64(cell_t target, cell_t source, cell_t nelems, cell_t PE_root,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync);
static cell_t pf_shmem_broadcast32(cell_t target, cell_t source, cell_t nelems, cell_t PE_root,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync);
static cell_t pf_shmem_collect64(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync);
static cell_t pf_shmem_fcollect64(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync);
static cell_t pf_shmem_alltoall64(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync);
static cell_t pf_shmem_collect32(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync);
static cell_t pf_shmem_fcollect32(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync);
static cell_t pf_shmem_alltoall32(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync);
static cell_t pf_shmem_int_and_to_all(cell_t target, cell_t source, cell_t nreduce,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync);
static cell_t pf_shmem_int_max_to_all(cell_t target, cell_t source, cell_t nreduce,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync);
static cell_t pf_shmem_int_min_to_all(cell_t target, cell_t source, cell_t nreduce,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync);
static cell_t pf_shmem_int_sum_to_all(cell_t target, cell_t source, cell_t nreduce,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync);
static cell_t pf_shmem_int_prod_to_all(cell_t target, cell_t source, cell_t nreduce,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync);
static cell_t pf_shmem_int_or_to_all(cell_t target, cell_t source, cell_t nreduce,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync);
static cell_t pf_shmem_int_xor_to_all(cell_t target, cell_t source, cell_t nreduce,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync);
static cell_t pf_shmem_double_sum_to_all(cell_t target, cell_t source, cell_t nreduce,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync);
static cell_t pf_shmem_fence(void);
static cell_t pf_shmem_set_lock(cell_t lock);
static cell_t pf_shmem_clear_lock(cell_t lock);
static cell_t pf_shmem_test_lock(cell_t lock);
static cell_t pf_shmem_long_atomic_fetch(cell_t target, cell_t pe);
static cell_t pf_shmem_long_atomic_set(cell_t target, cell_t value, cell_t pe);
static cell_t pf_shmem_long_atomic_add(cell_t target, cell_t value, cell_t pe);
static cell_t pf_shmem_long_atomic_fetch_add(cell_t target, cell_t value, cell_t pe);
static cell_t pf_shmem_long_atomic_swap(cell_t target, cell_t value, cell_t pe);
static cell_t pf_shmem_long_atomic_compare_swap(cell_t target, cell_t cond, cell_t value, cell_t pe);
static cell_t pf_shmem_long_atomic_inc(cell_t target, cell_t pe);
static cell_t pf_shmem_long_atomic_fetch_inc(cell_t target, cell_t pe);
/****************************************************************
** Step 1: Put your own special glue routines here
**     or link them in from another file or library.
****************************************************************/
/* This op switched on TOS to choose which shmem function to call
   The rest will be handled in FORTH code
*/

static cell_t pf_shmem_put(cell_t dest, cell_t source, cell_t nelems, cell_t pe)
{
    size_t numBytes = (size_t)nelems * sizeof(cell_t);
    int targetPe = (int)pe;

    //fprintf(stderr, "SHMEM_PUT: %p %p  0x%08x 0x%08x\n", M_STACK(3), M_STACK(2), M_STACK(1), M_STACK(0));
    if( (dest == source) && (targetPe != shmem_my_pe()) )
    {
        void *temp = pfAllocMem( (cell_t)numBytes );
        if( temp == NULL ) return -1;
        pfCopyMemory( temp, (void *)source, numBytes );
        shmem_putmem((char*)dest, temp, numBytes, targetPe);
        pfFreeMem( temp );
    }
    else
    {
        shmem_putmem((char*)dest, (char*)source, numBytes, targetPe);
    }
    return 0;
}

static cell_t pf_shmem_get(cell_t dest, cell_t source, cell_t nelems, cell_t pe)
{
    size_t numBytes = (size_t)nelems * sizeof(cell_t);
    int sourcePe = (int)pe;

    //fprintf(stderr, "SHMEM_GET: %p %p  0x%08x 0x%08x\n", M_STACK(3), M_STACK(2), M_STACK(1), M_STACK(0));
    if( (dest == source) && (sourcePe != shmem_my_pe()) )
    {
        void *temp = pfAllocMem( (cell_t)numBytes );
        if( temp == NULL ) return -1;
        shmem_getmem(temp, (char*)source, numBytes, sourcePe);
        pfCopyMemory( (void *)dest, temp, numBytes );
        pfFreeMem( temp );
    }
    else
    {
        shmem_getmem((char*)dest, (char*)source, numBytes, sourcePe);
    }
    return 0;
}

static cell_t pf_shmem_put32(cell_t dest, cell_t source, cell_t nelems, cell_t pe)
{
    shmem_put32((void*)dest, (void*)source, (size_t)nelems, (int)pe);
    return 0;
}

static cell_t pf_shmem_get32(cell_t dest, cell_t source, cell_t nelems, cell_t pe)
{
    shmem_get32((void*)dest, (void*)source, (size_t)nelems, (int)pe);
    return 0;
}

static cell_t pf_shmem_global_exit(cell_t status)
{
    shmem_global_exit((int)status);
    return 0;
}

static cell_t pf_shmem_barrier(cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync)
{
    shmem_barrier((int)PE_start, (int)logPE_stride, (int)PE_size, (long*)sync);
    return 0;
}

static cell_t pf_shmem_malloc(cell_t size)
{
    return (cell_t)shmem_malloc((size_t)size);
}

static cell_t pf_shmem_free(cell_t addr)
{
    shmem_free((void*)addr);
    return 0;
}

static cell_t pf_shmem_ptr(cell_t addr, cell_t pe)
{
    return (cell_t)shmem_ptr((void*)addr, (int)pe);
}

static cell_t pf_shmem_broadcast64(cell_t target, cell_t source, cell_t nelems, cell_t PE_root,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync)
{
    shmem_broadcast64((void*)target, (void*)source, (size_t)nelems, (int)PE_root,
        (int)PE_start, (int)logPE_stride, (int)PE_size, (long*)sync);
    return 0;
}

static cell_t pf_shmem_broadcast32(cell_t target, cell_t source, cell_t nelems, cell_t PE_root,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync)
{
    shmem_broadcast32((void*)target, (void*)source, (size_t)nelems, (int)PE_root,
        (int)PE_start, (int)logPE_stride, (int)PE_size, (long*)sync);
    return 0;
}

static cell_t pf_shmem_collect64(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync)
{
    shmem_collect64((void*)target, (void*)source, (size_t)nelems,
        (int)PE_start, (int)logPE_stride, (int)PE_size, (long*)sync);
    return 0;
}

static cell_t pf_shmem_fcollect64(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync)
{
    shmem_fcollect64((void*)target, (void*)source, (size_t)nelems,
        (int)PE_start, (int)logPE_stride, (int)PE_size, (long*)sync);
    return 0;
}

static cell_t pf_shmem_alltoall64(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync)
{
    shmem_alltoall64((void*)target, (void*)source, (size_t)nelems,
        (int)PE_start, (int)logPE_stride, (int)PE_size, (long*)sync);
    return 0;
}

static cell_t pf_shmem_collect32(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync)
{
    shmem_collect32((void*)target, (void*)source, (size_t)nelems,
        (int)PE_start, (int)logPE_stride, (int)PE_size, (long*)sync);
    return 0;
}

static cell_t pf_shmem_fcollect32(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync)
{
    shmem_fcollect32((void*)target, (void*)source, (size_t)nelems,
        (int)PE_start, (int)logPE_stride, (int)PE_size, (long*)sync);
    return 0;
}

static cell_t pf_shmem_alltoall32(cell_t target, cell_t source, cell_t nelems,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t sync)
{
    shmem_alltoall32((void*)target, (void*)source, (size_t)nelems,
        (int)PE_start, (int)logPE_stride, (int)PE_size, (long*)sync);
    return 0;
}

#define PF_SHMEM_INT_REDUCTION(name) \
static cell_t pf_##name(cell_t target, cell_t source, cell_t nreduce, \
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync) \
{ \
    name((int*)target, (int*)source, (int)nreduce, (int)PE_start, \
        (int)logPE_stride, (int)PE_size, (int*)work, (long*)sync); \
    return 0; \
}

PF_SHMEM_INT_REDUCTION(shmem_int_and_to_all)
PF_SHMEM_INT_REDUCTION(shmem_int_max_to_all)
PF_SHMEM_INT_REDUCTION(shmem_int_min_to_all)
PF_SHMEM_INT_REDUCTION(shmem_int_sum_to_all)
PF_SHMEM_INT_REDUCTION(shmem_int_prod_to_all)
PF_SHMEM_INT_REDUCTION(shmem_int_or_to_all)
PF_SHMEM_INT_REDUCTION(shmem_int_xor_to_all)

#undef PF_SHMEM_INT_REDUCTION

static cell_t pf_shmem_double_sum_to_all(cell_t target, cell_t source, cell_t nreduce,
    cell_t PE_start, cell_t logPE_stride, cell_t PE_size, cell_t work, cell_t sync)
{
    shmem_double_sum_to_all((double*)target, (double*)source, (int)nreduce, (int)PE_start,
        (int)logPE_stride, (int)PE_size, (double*)work, (long*)sync);
    return 0;
}

static cell_t pf_shmem_fence(void)
{
    shmem_fence();
    return 0;
}

static cell_t pf_shmem_set_lock(cell_t lock)
{
    shmem_set_lock((long*)lock);
    return 0;
}

static cell_t pf_shmem_clear_lock(cell_t lock)
{
    shmem_clear_lock((long*)lock);
    return 0;
}

static cell_t pf_shmem_test_lock(cell_t lock)
{
    return (cell_t)shmem_test_lock((long*)lock);
}

static cell_t pf_shmem_long_atomic_fetch(cell_t target, cell_t pe)
{
    return (cell_t)shmem_long_atomic_fetch((long*)target, (int)pe);
}

static cell_t pf_shmem_long_atomic_set(cell_t target, cell_t value, cell_t pe)
{
    shmem_long_atomic_set((long*)target, (long)value, (int)pe);
    return 0;
}

static cell_t pf_shmem_long_atomic_add(cell_t target, cell_t value, cell_t pe)
{
    shmem_long_atomic_add((long*)target, (long)value, (int)pe);
    return 0;
}

static cell_t pf_shmem_long_atomic_fetch_add(cell_t target, cell_t value, cell_t pe)
{
    return (cell_t)shmem_long_atomic_fetch_add((long*)target, (long)value, (int)pe);
}

static cell_t pf_shmem_long_atomic_swap(cell_t target, cell_t value, cell_t pe)
{
    return (cell_t)shmem_long_atomic_swap((long*)target, (long)value, (int)pe);
}

static cell_t pf_shmem_long_atomic_compare_swap(cell_t target, cell_t cond, cell_t value, cell_t pe)
{
    return (cell_t)shmem_long_atomic_compare_swap((long*)target, (long)cond, (long)value, (int)pe);
}

static cell_t pf_shmem_long_atomic_inc(cell_t target, cell_t pe)
{
    shmem_long_atomic_inc((long*)target, (int)pe);
    return 0;
}

static cell_t pf_shmem_long_atomic_fetch_inc(cell_t target, cell_t pe)
{
    return (cell_t)shmem_long_atomic_fetch_inc((long*)target, (int)pe);
}

/****************************************************************
** Step 2: Create CustomFunctionTable.
**     Do not change the name of CustomFunctionTable!
**     It is used by the pForth kernel.
****************************************************************/

#ifdef PF_NO_GLOBAL_INIT
/******************
** If your loader does not support global initialization, then you
** must define PF_NO_GLOBAL_INIT and provide a function to fill
** the table. Some embedded system loaders require this!
** Do not change the name of LoadCustomFunctionTable()!
** It is called by the pForth kernel.
*/
#define NUM_CUSTOM_FUNCTIONS  (43)
CFunc0 CustomFunctionTable[NUM_CUSTOM_FUNCTIONS];

Err LoadCustomFunctionTable( void )
{
    return 0;
}

#else
/******************
** If your loader supports global initialization (most do.) then just
** create the table like this.
*/
CFunc0 CustomFunctionTable[] =
{
    (CFunc0) shmem_n_pes,
    (CFunc0) shmem_my_pe,
    (CFunc0) pf_shmem_put,
    (CFunc0) pf_shmem_get,
    (CFunc0) pf_shmem_global_exit,
    (CFunc0) pf_shmem_barrier,
    (CFunc0) shmem_barrier_all,
    (CFunc0) pf_shmem_malloc,
    (CFunc0) pf_shmem_broadcast64,
    (CFunc0) shmem_sync_all,
    (CFunc0) pf_shmem_collect64,
    (CFunc0) pf_shmem_fcollect64,
    (CFunc0) pf_shmem_int_and_to_all,
    (CFunc0) pf_shmem_int_max_to_all,
    (CFunc0) pf_shmem_int_min_to_all,
    (CFunc0) pf_shmem_int_sum_to_all,
    (CFunc0) pf_shmem_int_prod_to_all,
    (CFunc0) pf_shmem_int_or_to_all,
    (CFunc0) pf_shmem_int_xor_to_all,
    (CFunc0) pf_shmem_alltoall64,
    (CFunc0) pf_shmem_double_sum_to_all,
    (CFunc0) shmem_quiet,
    (CFunc0) wtime,
    (CFunc0) pf_shmem_free,
    (CFunc0) pf_shmem_put32,
    (CFunc0) pf_shmem_get32,
    (CFunc0) pf_shmem_broadcast32,
    (CFunc0) pf_shmem_collect32,
    (CFunc0) pf_shmem_fcollect32,
    (CFunc0) pf_shmem_alltoall32,
    (CFunc0) pf_shmem_fence,
    (CFunc0) pf_shmem_ptr,
    (CFunc0) pf_shmem_set_lock,
    (CFunc0) pf_shmem_clear_lock,
    (CFunc0) pf_shmem_test_lock,
    (CFunc0) pf_shmem_long_atomic_fetch,
    (CFunc0) pf_shmem_long_atomic_set,
    (CFunc0) pf_shmem_long_atomic_add,
    (CFunc0) pf_shmem_long_atomic_fetch_add,
    (CFunc0) pf_shmem_long_atomic_swap,
    (CFunc0) pf_shmem_long_atomic_compare_swap,
    (CFunc0) pf_shmem_long_atomic_inc,
    (CFunc0) pf_shmem_long_atomic_fetch_inc,
};
#endif

/****************************************************************
** Step 3: Add custom functions to the dictionary.
**     Do not change the name of CompileCustomFunctions!
**     It is called by the pForth kernel.
****************************************************************/

#if (!defined(PF_NO_INIT)) && (!defined(PF_NO_SHELL))
Err CompileCustomFunctions( void )
{
    Err err;
    int i = 0;
/* Compile Forth words that call your custom functions.
** Make sure order of functions matches that in LoadCustomFunctionTable().
** Parameters are: Name in UPPER CASE, Function, Index, Mode, NumParams
*/
    err = CreateGlueToC( "PES", i++, C_RETURNS_VALUE, 0 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "PE", i++, C_RETURNS_VALUE, 0 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "PUT", i++, C_RETURNS_VOID, 4 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "GET", i++, C_RETURNS_VOID, 4 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "GLOBAL-EXIT", i++, C_RETURNS_VALUE, 1 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "BARRIER", i++, C_RETURNS_VOID, 4 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "BARRIER-ALL", i++, C_RETURNS_VOID, 0 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "SHARED", i++, C_RETURNS_VALUE, 1 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "BROADCAST", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "SYNC", i++, C_RETURNS_VOID, 0 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "COLLECT", i++, C_RETURNS_VOID, 7 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "FCOLLECT", i++, C_RETURNS_VOID, 7 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "AND-REDUCTION", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "MAX-REDUCTION", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "MIN-REDUCTION", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "SUM-REDUCTION", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "PROD-REDUCTION", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "OR-REDUCTION", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "XOR-REDUCTION", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ALL-TO-ALL", i++, C_RETURNS_VOID, 7 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "FSUM-REDUCTION", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "QUIET", i++, C_RETURNS_VOID, 0 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "WTIME", i++, C_RETURNS_VALUE, 0 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "SHARED-FREE", i++, C_RETURNS_VOID, 1 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "PUT32", i++, C_RETURNS_VOID, 4 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "GET32", i++, C_RETURNS_VOID, 4 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "BROADCAST32", i++, C_RETURNS_VOID, 8 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "COLLECT32", i++, C_RETURNS_VOID, 7 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "FCOLLECT32", i++, C_RETURNS_VOID, 7 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ALL-TO-ALL32", i++, C_RETURNS_VOID, 7 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "FENCE", i++, C_RETURNS_VOID, 0 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "PTR", i++, C_RETURNS_VALUE, 2 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "SET-LOCK", i++, C_RETURNS_VOID, 1 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "CLEAR-LOCK", i++, C_RETURNS_VOID, 1 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "TEST-LOCK", i++, C_RETURNS_VALUE, 1 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ATOMIC-FETCH", i++, C_RETURNS_VALUE, 2 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ATOMIC-SET", i++, C_RETURNS_VOID, 3 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ATOMIC-ADD", i++, C_RETURNS_VOID, 3 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ATOMIC-FETCH-ADD", i++, C_RETURNS_VALUE, 3 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ATOMIC-SWAP", i++, C_RETURNS_VALUE, 3 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ATOMIC-COMPARE-SWAP", i++, C_RETURNS_VALUE, 4 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ATOMIC-INC", i++, C_RETURNS_VOID, 2 );
    if( err < 0 ) return err;
    err = CreateGlueToC( "ATOMIC-FETCH-INC", i++, C_RETURNS_VALUE, 2 );
    if( err < 0 ) return err;

    return 0;
}
#else
Err CompileCustomFunctions( void ) { return 0; }
#endif

/****************************************************************
** Step 4: Recompile using compiler option PF_USER_CUSTOM
**         and link with your code.
**         Then rebuild the Forth using "pforth -i system.fth"
**         Test:   10 Ctest0 ( should print message then '11' )
****************************************************************/

#endif  /* PF_USER_CUSTOM */
