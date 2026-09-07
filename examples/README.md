# pforth-shmem examples

Build from `build/unix` first:

```
make SHMEM=1
```

Run examples from the repository root:

```
./pforth-shmem -n 4
./pforth-shmem -n 4 examples/pi-reduction.fth
./pforth-shmem -n 4 examples/hot-plate.fth
./pforth-shmem -n 4 examples/game-of-life.fth
./pforth-shmem -n 2 examples/raw-shmem.fth
```

Or run examples directly from `build/unix`:

```
oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ../../examples/pi-reduction.fth
oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ../../examples/hot-plate.fth
oshrun --mca memheap_base_max_segments 128 -n 4 ./pforth_standalone ../../examples/game-of-life.fth
oshrun --mca memheap_base_max_segments 128 -n 2 ./pforth_standalone ../../examples/raw-shmem.fth
```

The pi example uses row-block decomposition and the `all-reduce-sum` helper. The Hot Plate and Game of Life examples use row-block decomposition with a replicated grid. Each PE computes a band of rows, then publishes those rows to every PE with `put-cells` so the next iteration sees a complete replicated grid. `raw-shmem.fth` shows the lower-level words directly.

The higher-level examples use `fth/shmem.fth`, which is also loaded into the default dictionary. It hides the standard sync/work buffers for common collectives and provides Forth-style words such as `shared-grid`, `remote!`, `remote@`, `all-reduce-sum`, `all-barrier`, and `pe0?`.
