#!/bin/bash
TESTS=( "segreduce" "segscan" "scan" "reduce")
ARGS=( "    segreduce (+) 0 (zip xs bs)" "    segscan (+) 0 (zip xs bs)" "    scan (+) 0 xs" "    [reduce (+) 0 xs]" )

for i in 0 1 2 3
do
    cat segscan.fut > segscan-new.fut
    echo "${ARGS[$i]}" >> segscan-new.fut
    echo "  "
    echo "NEW TEST IS +++++++++++++++++"
    echo "${TESTS[$i]}"
    echo "Futhark C"
    futhark-bench --compiler=futhark-c segscan-new.fut
    echo "Futhark OpenCL"
    futhark-bench --compiler=futhark-opencl segscan-new.fut
done
