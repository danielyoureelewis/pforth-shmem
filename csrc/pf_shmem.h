/* OpenSHMEM wrapper for pForth.
**
** Define PF_USE_OPENSHMEM to build against a real OpenSHMEM implementation.
** Without it, provide a single-PE fallback so the interpreter and core tests
** can run on systems without OpenSHMEM development headers.
*/
#ifndef _pf_shmem_h
#define _pf_shmem_h

#ifdef PF_USE_OPENSHMEM

#include <shmem.h>

#else

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define SHMEM_BARRIER_SYNC_SIZE (1)
#define SHMEM_SYNC_VALUE (0L)

static inline void shmem_init( void )
{
}

static inline int shmem_n_pes( void )
{
    return 1;
}

static inline int shmem_my_pe( void )
{
    return 0;
}

static inline void shmem_barrier_all( void )
{
}

static inline void shmem_sync_all( void )
{
}

static inline void shmem_quiet( void )
{
}

static inline void shmem_fence( void )
{
}

static inline void shmem_global_exit( int status )
{
    exit( status );
}

static inline void *shmem_malloc( size_t size )
{
    return malloc( size );
}

static inline void shmem_free( void *ptr )
{
    free( ptr );
}

static inline void *shmem_ptr( const void *ptr, int pe )
{
    return (pe == 0) ? (void *)(uintptr_t)ptr : NULL;
}

static inline void shmem_putmem( void *dest, const void *source, size_t nelems, int pe )
{
    (void) pe;
    memcpy( dest, source, nelems );
}

static inline void shmem_getmem( void *dest, const void *source, size_t nelems, int pe )
{
    (void) pe;
    memcpy( dest, source, nelems );
}

static inline void shmem_put32( void *dest, const void *source, size_t nelems, int pe )
{
    (void) pe;
    memcpy( dest, source, nelems * sizeof(int) );
}

static inline void shmem_get32( void *dest, const void *source, size_t nelems, int pe )
{
    (void) pe;
    memcpy( dest, source, nelems * sizeof(int) );
}

static inline void shmem_barrier( int PE_start, int logPE_stride, int PE_size, long *pSync )
{
    (void) PE_start;
    (void) logPE_stride;
    (void) PE_size;
    (void) pSync;
}

static inline void shmem_broadcast64( void *target, const void *source, size_t nelems,
    int PE_root, int PE_start, int logPE_stride, int PE_size, long *pSync )
{
    (void) PE_root;
    (void) PE_start;
    (void) logPE_stride;
    (void) PE_size;
    (void) pSync;
    memcpy( target, source, nelems * sizeof(long) );
}

static inline void shmem_broadcast32( void *target, const void *source, size_t nelems,
    int PE_root, int PE_start, int logPE_stride, int PE_size, long *pSync )
{
    (void) PE_root;
    (void) PE_start;
    (void) logPE_stride;
    (void) PE_size;
    (void) pSync;
    memcpy( target, source, nelems * sizeof(int) );
}

static inline void shmem_collect64( void *target, const void *source, size_t nelems,
    int PE_start, int logPE_stride, int PE_size, long *pSync )
{
    (void) PE_start;
    (void) logPE_stride;
    (void) PE_size;
    (void) pSync;
    memcpy( target, source, nelems * sizeof(long) );
}

static inline void shmem_collect32( void *target, const void *source, size_t nelems,
    int PE_start, int logPE_stride, int PE_size, long *pSync )
{
    (void) PE_start;
    (void) logPE_stride;
    (void) PE_size;
    (void) pSync;
    memcpy( target, source, nelems * sizeof(int) );
}

static inline void shmem_fcollect64( void *target, const void *source, size_t nelems,
    int PE_start, int logPE_stride, int PE_size, long *pSync )
{
    shmem_collect64( target, source, nelems, PE_start, logPE_stride, PE_size, pSync );
}

static inline void shmem_fcollect32( void *target, const void *source, size_t nelems,
    int PE_start, int logPE_stride, int PE_size, long *pSync )
{
    shmem_collect32( target, source, nelems, PE_start, logPE_stride, PE_size, pSync );
}

static inline void shmem_alltoall64( void *target, const void *source, size_t nelems,
    int PE_start, int logPE_stride, int PE_size, long *pSync )
{
    (void) PE_start;
    (void) logPE_stride;
    (void) PE_size;
    (void) pSync;
    memcpy( target, source, nelems * sizeof(long) );
}

static inline void shmem_alltoall32( void *target, const void *source, size_t nelems,
    int PE_start, int logPE_stride, int PE_size, long *pSync )
{
    (void) PE_start;
    (void) logPE_stride;
    (void) PE_size;
    (void) pSync;
    memcpy( target, source, nelems * sizeof(int) );
}

static inline void shmem_set_lock( volatile long *lock )
{
    *lock = 1;
}

static inline void shmem_clear_lock( volatile long *lock )
{
    *lock = 0;
}

static inline int shmem_test_lock( volatile long *lock )
{
    if( *lock != 0 ) return 1;
    *lock = 1;
    return 0;
}

static inline long shmem_long_atomic_fetch( const long *target, int pe )
{
    (void) pe;
    return *target;
}

static inline void shmem_long_atomic_set( long *target, long value, int pe )
{
    (void) pe;
    *target = value;
}

static inline void shmem_long_atomic_add( long *target, long value, int pe )
{
    (void) pe;
    *target += value;
}

static inline long shmem_long_atomic_fetch_add( long *target, long value, int pe )
{
    long oldValue;
    (void) pe;
    oldValue = *target;
    *target += value;
    return oldValue;
}

static inline long shmem_long_atomic_swap( long *target, long value, int pe )
{
    long oldValue;
    (void) pe;
    oldValue = *target;
    *target = value;
    return oldValue;
}

static inline long shmem_long_atomic_compare_swap( long *target, long cond, long value, int pe )
{
    long oldValue;
    (void) pe;
    oldValue = *target;
    if( oldValue == cond ) *target = value;
    return oldValue;
}

static inline void shmem_long_atomic_inc( long *target, int pe )
{
    (void) pe;
    ++(*target);
}

static inline long shmem_long_atomic_fetch_inc( long *target, int pe )
{
    long oldValue;
    (void) pe;
    oldValue = *target;
    ++(*target);
    return oldValue;
}

#define PF_SHMEM_INT_REDUCTION(name) \
static inline void name( int *target, const int *source, int nreduce, \
    int PE_start, int logPE_stride, int PE_size, int *pWrk, long *pSync ) \
{ \
    (void) PE_start; \
    (void) logPE_stride; \
    (void) PE_size; \
    (void) pWrk; \
    (void) pSync; \
    memcpy( target, source, (size_t)nreduce * sizeof(int) ); \
}

PF_SHMEM_INT_REDUCTION( shmem_int_and_to_all )
PF_SHMEM_INT_REDUCTION( shmem_int_max_to_all )
PF_SHMEM_INT_REDUCTION( shmem_int_min_to_all )
PF_SHMEM_INT_REDUCTION( shmem_int_sum_to_all )
PF_SHMEM_INT_REDUCTION( shmem_int_prod_to_all )
PF_SHMEM_INT_REDUCTION( shmem_int_or_to_all )
PF_SHMEM_INT_REDUCTION( shmem_int_xor_to_all )

#undef PF_SHMEM_INT_REDUCTION

static inline void shmem_double_sum_to_all( double *target, const double *source, int nreduce,
    int PE_start, int logPE_stride, int PE_size, double *pWrk, long *pSync )
{
    (void) PE_start;
    (void) logPE_stride;
    (void) PE_size;
    (void) pWrk;
    (void) pSync;
    memcpy( target, source, (size_t)nreduce * sizeof(double) );
}

#endif /* PF_USE_OPENSHMEM */

#endif /* _pf_shmem_h */
