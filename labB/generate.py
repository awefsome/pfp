#!/bin/python
import subprocess

def main():
    sizes = [100, 1000, 10000, 100000, 1000000, 5000000, 10000000]
    bounds =  [-10000, 10000]
    num_files = 1
    for size in sizes:
        filename_base = "data-" + str(size) + "-"
        filename_suffix = ".dat"
        command = [ "futhark-dataset"
                  , "-b"
                  , "--i32-bounds=" + str(bounds[0]) + ":" + str(bounds[1])
                  , "-g"
                  , "[" + str(size) + "]i32"
                  , "--i32-bounds=" + str(bounds[0]) + ":" + str(bounds[1])
                  , "-g"
                  , "[" + str(size) + "]i32"
                  ]

        for i in range(num_files):
            file = open(filename_base + str(i) + filename_suffix, "w")
            subprocess.call(command, stdout=file, stderr=subprocess.STDOUT)
            file.close()

main()
