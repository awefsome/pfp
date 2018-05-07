
let segscan [n] 't (op: t -> t -> t) (ne: t) (arr: [n](t, bool)): [n]t =
    let (xs, _) = unzip(scan (\(v1, f1) (v2, f2) ->
                            if f2 then (v2, true) else (op v1 v2, f1 || f2))
                        (ne, false) arr)
    in xs


let segreduce [n] 't (op: t -> t -> t) (ne: t) (arr: [n](t, bool)): []t =
    let segscanned = segscan op ne arr
    let (_, bs)    = unzip arr
    let offsets    = scan (+) 0 (map i32.bool bs)
    let put_in f i = if f then i-1 else 0-1
    let is         = map2 put_in bs offsets
    in take (offsets[n-1]) (scatter (copy segscanned) is segscanned)

-- ==
-- tags { 100 10000 1000000 1000000000 }
-- compiled input @data-segmented-100.dat
-- compiled input @data-segmented-10000.dat
-- compiled input @data-segmented-1000000.dat

let main [n] (xs: [n]i32) (bs: [n]bool) : []i32 =
    --segreduce (+) 0 (zip xs bs)
    --segscan (+) 0 (zip xs bs)
    --scan (+) 0 xs
    --[reduce (+) 0 xs]
