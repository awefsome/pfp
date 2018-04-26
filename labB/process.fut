-- Given two signals, compute the maximum, pair-wise difference
-- ==
-- tags {100 1000 10000 100000 1000000 5000000 10000000}
-- compiled input @data-process-100.dat
-- compiled input @data-process-1000.dat
-- compiled input @data-process-10000.dat
-- compiled input @data-process-100000.dat
-- compiled input @data-process-1000000.dat
-- compiled input @data-process-5000000.dat
-- compiled input @data-process-10000000.dat

let max (x: i32) (y: i32) : i32 =
    if x > y then x else y

let s1 = [ 23, 45, -23, 44, 23, 54, 23, 12, 34, 54, 7, 2,  4, 67 ]
let s2 = [ -2,  3,   4, 57, 34,  2,  5, 56, 56,  3, 3, 5, 77, 89 ]

let diff (x: i32) (y: i32) : i32 = i32.abs(x - y)

let process (x: []i32) (y: []i32) : i32 =
    reduce max 0 (map2 diff x y)

let process_idx [n] (x: [n]i32) (y: [n]i32) : (i32, i32) =
    reduce (\(x, i) (y, j) ->
            if x < y then (y, j) else (x, i))
        (i32.smallest, -1)
        (zip (map2 diff x y) (iota n ))

let main (x: []i32) (y: []i32) : (i32, i32) = process_idx x y
