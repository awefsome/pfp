-- Approximate the integral of a function using the monte carlo algorithm
-- ==
-- tags {integral100 integral10000 integral1000000}
-- compiled input @data-montecarlo-100.dat
-- compiled input @data-montecarlo-10000.dat
-- compiled input @data-montecarlo-1000000.dat

import "/futlib/sobol"
import "/futlib/sobol-dir-50"

module S2 = Sobol sobol_dir { let D = 2 }

let ftest (x:f32) (y:f32): f32 =
    2.0f32*x*x*x*x*x*x*y*y - x*x*x*x*x*x*y
    + 3.0f32*x*x*x*y*y*y - x*x*y*y*y +
    x*x*x*y - 3.0f32*x*y*y + x*y -
    5.0f32*y + 2.0f32*x*x*x*x*x*y*y*y*y -
    2.0f32*x*x*x*x*x*y*y*y*y*y + 250.0f32

module R = S2.Reduce { type t = f32
                       let ne = 0f32
                       let op (x:f32) (y:f32) = x f32.+ y
                       let f (v : [2]f64) : f32 =
                         let x = f32.f64(v[0])
                         let y = f32.f64(v[1])
                         in ftest x y }

let montecarlointegral [n] (xs: [n]f32)
                           (ys: [n]f32)
                           (f: f32 -> f32 -> f32)
                           : f32 =
    (4f32 / f32.i32(n)) * (reduce (+) 0f32 (map2 f xs ys))

let diff (x: f32) (y: f32) : f32 = f32.abs(x - y)

let process_idx [n] (x: [n]f32) (y: [n]f32) : (f32, i32) =
    reduce (\(x, i) (y, j) ->
            if x > y then (y, j) else (x, i))
        (f32.largest, -1)
        (zip (map2 diff x y) (iota n ))

let main (xs: []f32) (ys: []f32) : f32 = montecarlointegral xs ys ftest
--let main (n: i32) : (f32, i32) =
    --process_idx (map (\x -> R.run x) (iota n)) (map (\_ -> 983.21f32) (iota n))
