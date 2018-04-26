-- Approximate pi by utilizing the monte carlo algorithm
-- ==
-- tags {pi100 pi10000 pi1000000}
-- compiled input @data-montecarlo-100.dat
-- compiled input @data-montecarlo-10000.dat
-- compiled input @data-montecarlo-1000000.dat

let in_circle (x: f32) (y: f32) : f32 =
    if (x - 1f32)**2f32 + (y - 1f32)**2f32 <= 1f32 then 1f32 else 0f32

let estimate_pi [n] (xs: [n]f32) (ys: [n]f32) : f32 =
    4f32 * ((reduce (+) 0f32 (map2 in_circle xs ys)) / f32.i32(n))



let main (xs: []f32) (ys: []f32) : f32 = estimate_pi xs ys
