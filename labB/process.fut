-- Given two signals, compute the maximum, pair-wise difference
-- ==
-- tags {100 1000 10000 100000 1000000 5000000 10000000}
-- compiled input @data-100-0.dat
-- compiled input @data-1000-0.dat
-- compiled input @data-10000-0.dat
-- compiled input @data-100000-0.dat
-- compiled input @data-1000000-0.dat
-- compiled input @data-5000000-0.dat
-- compiled input @data-10000000-0.dat

let max (x: i32) (y: i32) : i32 =
    if x > y then x else y

let diff (x: i32) (y: i32) : i32 = i32.abs(x - y)

let process (x: []i32) (y: []i32) : i32 =
    reduce max 0 (map2 diff x y)

let process_idx [n] (x: [n]i32) (y: [n]i32) : (i32, i32) =
    reduce (\(x, i) (y, j) ->
            if x < y then (y, j) else (x, i))
        (i32.smallest, -1)
        (zip (map2 diff x y) (iota n ))

let main (x: []i32) (y: []i32) : i32 = process x y
