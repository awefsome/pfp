-- We represent a spin as a single byte.  In principle, we need only
-- two values (-1 or 1), but Futhark represents booleans a a full byte
-- entirely, so using an i8 instead takes no more space, and makes the
-- arithmetic simpler.
type spin = i8

import "/futlib/random"

-- Pick an RNG engine and define random distributions for specific types.
module rng_engine = minstd_rand
module rand_f32 = uniform_real_distribution f32 rng_engine
module rand_i8 = uniform_int_distribution i8 rng_engine

-- We can create an few RNG state with 'rng_engine.rng_from_seed [x]',
-- where 'x' is some seed.  We can split one RNG state into many with
-- 'rng_engine.split_rng'.
--
-- For an RNG state 'r', we can generate random integers that are
-- either 0 or 1 by calling 'rand_i8.rand (0i8, 1i8) r'.
--
-- For an RNG state 'r', we can generate random floats in the range
-- (0,1) by calling 'rand_f32.rand (0f32, 1f32) r'.
--
-- Remember to consult https://futhark-lang.org/docs/futlib/random.html

let rand = rand_f32.rand (0f32, 1f32)

let chunksof 'a (w: i32) (h: i32) (ls: []a) : [w][]a =
    let grabber p = unsafe take w (drop ((p-1)*w) ls)
    in map grabber (iota h)

-- Create a new grid of a given size.  Also produce an identically
-- sized array of RNG states.
entry random_grid (seed: i32) (w: i32) (h: i32)
                : ([w][h]rng_engine.rng, [w][h]spin) =
    let (rs, xs) = unzip (map (\r ->
            let (rng, x) = rand_i8.rand (0i8, 1i8) r
            in (rng, (0i8-1i8)**x))
            (rng_engine.split_rng (w * h) (rng_engine.rng_from_seed [seed])))
    in (chunksof w h rs, chunksof w h xs)

-- Compute $\Delta_e$ for each spin in the grid, using wraparound at
-- the edges.
entry deltas [w][h] (spins: [w][h]spin): [w][h]i8 =
    let updow = map2 (\xs ys -> map2 (+) xs ys)
                    (rotate@1 1 spins) (rotate@1 (0-1) spins)
    let lerig = map2 (\xs ys -> map2 (+) xs ys)
                    (rotate@0 1 spins) (rotate@0 (0-1) spins)
    in map2 (\cs us -> map2 (\c u -> 2i8 * c * u) cs us) spins
        (map2 (\xs ys -> map2 (+) xs ys) updow lerig)


-- The sum of all deltas of a grid.  The result is a measure of how
-- ordered the grid is.
entry delta_sum [w][h] (spins: [w][h]spin): i32 =
   deltas spins |> flatten |> map1 i32.i8 |> reduce (+) 0

-- Take one step in the Ising 2D simulation.
entry step [w][h] (abs_temp: f32) (samplerate: f32)
                  (rngs: [w][h]rng_engine.rng) (spins: [w][h]spin)
                : ([w][h]rng_engine.rng, [w][h]spin) =
    let delta_es = deltas spins
    let abrngs   = map (\rs ->
        map (\r ->
            let (rng, a) = rand r
            let (rng, b) = rand rng
            in (rng, a, b)) rs) rngs
    in unzip (map3 (\abr delta_e spin ->
        map3 (\(rng, a, b) d c ->
            if a < samplerate && (d < -d || b < f32.exp(f32.i8(0i8-d) / abs_temp))
            then (rng, 0i8-c)
            else (rng, c)) abr delta_e spin) abrngs delta_es spins)

import "/futlib/colour"

-- | Turn a grid of spins into an array of pixel values, ready to be
-- blitted to the screen.
entry render [w][h] (spins: [w][h]spin): [w][h]argb.colour =
  let pixel spin = if spin == -1i8
                   then argb.(bright <| light red)
                   else argb.(bright <| light blue)
  in map1 (map1 pixel) spins

-- | Just for benchmarking.
-- ==
-- tags { 10 100 1000 5000 }
-- compiled input { 25f32 0.25f32 1000 1000 10 }
-- compiled input { 25f32 0.25f32 1000 1000 100 }
-- compiled input { 25f32 0.25f32 1000 1000 1000 }
let main (abs_temp: f32) (samplerate: f32)
         (w: i32) (h: i32) (n: i32): [w][h]spin =
  (loop (rngs, spins) = random_grid 1337 w h for _i < n do
     step abs_temp samplerate rngs spins).2
