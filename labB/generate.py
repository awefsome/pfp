#!/bin/python
import subprocess

def main():
    sizes_process   = [100, 1000, 10000, 100000, 1000000, 5000000, 10000000]
    types_process   = ["i32", "i32"]
    bounds_process  = [ [-10000, 10000]
                      , [-10000, 10000]
                      ]

    sizes_montecarlo  = [100, 10000, 1000000]
    types_montecarlo  = ["f32", "f32"]
    bounds_montecarlo = [ [0, 2]
                        , [0, 2]
                        ]

    sizes_segmented  = [100, 10000, 1000000]
    types_segmented  = ["i32", "bool"]
    bounds_segmented = None

    generate(sizes_process, types_process, bounds_process, "process")
    generate(sizes_montecarlo, types_montecarlo, bounds_montecarlo, "montecarlo")
    generate(sizes_segmented, types_segmented, bounds_segmented, "segmented")

def generate(sizes, types, bounds, set):
    for size in sizes:
        filename = "data-" + set + "-" + str(size) + ".dat"
        command = [ "futhark-dataset"
                  , "-b"
                  ]
        for i in range(len(types)):
            if(bounds != None):
                command += ["--" + types[i] + "-bounds=" + str(bounds[i][0]) + ":" + str(bounds[i][1])]

            command += [ "-g"
                       , "[" + str(size) + "]" + types[i]
                       ]

        file = open(filename, "w")
        subprocess.call(command, stdout=file, stderr=subprocess.STDOUT)
        file.close()

main()
