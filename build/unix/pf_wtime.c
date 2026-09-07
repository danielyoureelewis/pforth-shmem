#include <sys/time.h>

unsigned long wtime( void )
{
    //static int sec = -1;
    struct timeval tv;
    //gettimeofday(&tv, (void *)0);
    gettimeofday(&tv, NULL);
    return tv.tv_sec*1.0e+6 + tv.tv_usec;
}
