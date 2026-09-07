set -eu

make clean

if command -v oshcc >/dev/null 2>&1 && command -v oshrun >/dev/null 2>&1
then
    OSHRUN=${OSHRUN:-oshrun}
    OSHRUN_FLAGS=${OSHRUN_FLAGS:---mca memheap_base_max_segments 128}
    make SHMEM=1 OSHRUN="$OSHRUN" OSHRUN_FLAGS="$OSHRUN_FLAGS"
    echo "running now..."
    "$OSHRUN" $OSHRUN_FLAGS -n 2 ./pforth_standalone test.fth
else
    make
    echo "OpenSHMEM tools not found; running serial fallback tests."
    ./pforth_standalone test.fth
fi
