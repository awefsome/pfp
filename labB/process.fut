let max (x: i32) (y: i32) : i32 =
    if x > y then x else y

let diff (x: i32) (y: i32) : i32 = i32.abs(x - y)

let process (x: []i32) (y: []i32) : i32 =
    reduce max 0 (map2 diff x y)

let main (x: []i32) (y: []i32): i32 = process x y
