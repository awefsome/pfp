import Data.List
import System.Random
import Criterion.Main
import Control.Parallel
import Control.Parallel.Strategies
import Control.Monad.Par

-- code borrowed from the Stanford Course 240h (Functional Systems in Haskell)
-- I suspect it comes from Bryan O'Sullivan, author of Criterion

data T a = T !a !Int


mean :: (RealFrac a) => [a] -> a
mean = fini . foldl' go (T 0 0)
  where
    fini (T a _) = a
    go (T m n) x = T m' n'
      where m' = m + (x - m) / fromIntegral n'
            n' = n + 1


resamples :: Int -> [a] -> [[a]]
resamples k xs =
    take (length xs - k) $
    zipWith (++) (inits xs) (map (drop k) (tails xs))

-- ASSIGNMENT 1 ---------------------------------------------------------------
jackknife :: ([a] -> b) -> [a] -> [b]
jackknife f = map f . resamples 500

pjackknife :: Int -> ([a] -> b) -> [a] -> [b]
pjackknife d f = parmap d f . resamples 500

rjackknife :: Int -> ([a] -> b) -> [a] -> [b]
rjackknife d f = rparmap d f . resamples 500

sjackknife :: ([a] -> b) -> [a] -> [b]
sjackknife f = sparmap f . resamples 500

parjackknife :: NFData b => ([a] -> b) -> [a] -> [b]
parjackknife f = pMap f . resamples 500

parmap :: Int -> ([a] -> b) -> [[a]] -> [b]
parmap d f []     = []
parmap 0 f xs     = map f xs
parmap d f (x:xs) = par h $ pseq t $ h : t
    where h     = f x
          t     = parmap (d-1) f xs

rparmap :: Int -> ([a] -> b) -> [[a]] -> [b]
rparmap d f xs = runEval $ rMap d f xs

rMap :: Int -> ([a] -> b) -> [[a]] -> Eval [b]
rMap d f []     = return []
rMap 0 f xs     = return $ map f xs
rMap d f (x:xs) = do
                h <- rpar (f x)
                t <- rMap (d-1) f xs
                return (h : t)

sparmap :: ([a] -> b) -> [[a]] -> [b]
sparmap f xs = map f xs `using` parList rseq

pMap :: NFData b => ([a] -> b) -> [[a]] -> [b]
pMap f []     = []
pMap f (x:xs) = runPar $ do
        i <- new
        j <- new
        fork (put i (f x))
        fork (put j (map f xs))
        h <- get i
        t <- get j
        return (h : t)

-- END ASSIGNMENT 1 -----------------------------------------------------------

-- ASSIGNMENT 2 ---------------------------------------------------------------
mergesort :: Ord a => [a] -> [a]
mergesort (x:[]) = [x]
mergesort xs     = merge (mergesort hs) (mergesort ts)
    where
        (hs, ts) = splitAt (n `div` 2) xs
        n        = l + 1 * l `mod` 2
        l        = length xs

merge :: Ord a => [a] -> [a] -> [a]
merge []     ts             = ts
merge hs     []             = hs
merge (h:hs) (t:ts) | h < t = h : merge hs     (t:ts)
                    | True  = t : merge (h:hs) ts

parmerge :: Ord a => Int -> [a] -> [a]
parmerge d (x:[]) = [x]
parmerge 0 xs     = mergesort xs
parmerge d xs = par h $ pseq t $ merge h t
    where
        h        = parmerge (d-1) hs
        t        = parmerge (d-1) ts
        (hs, ts) = splitAt (n `div` 2) xs
        n        = l + 1 * l `mod` 2
        l        = length xs

rmerge :: Ord a => Int -> [a] -> [a]
rmerge d xs = runEval $ rMergeMap d xs

rMergeMap :: Ord a => Int -> [a] -> Eval [a]
rMergeMap d (x:[]) = return [x]
rMergeMap 0 xs     = return $ mergesort xs
rMergeMap d xs     = do
                h <- rpar $ runEval $ rMergeMap (d-1) hs
                t <- rseq $ runEval $ rMergeMap (d-1) ts
                return (merge h t)
    where
        (hs, ts) = splitAt (n `div` 2) xs
        n        = l + 1 * l `mod` 2
        l        = length xs

-- END ASSIGNMENT 2 -----------------------------------------------------------


crud = zipWith (\x a -> sin (x / 300)**2 + a) [0..]

main = do
  let (xs,ys) = splitAt 1500  (take 6000
                               (randoms (mkStdGen 211570155)) :: [Float] )
  -- handy (later) to give same input different parallel functions

  let rs = crud xs ++ ys
  putStrLn $ "sample mean:    " ++ show (mean rs)

  let j = jackknife mean rs :: [Float]
  putStrLn $ "jack mean min:  " ++ show (minimum j)
  putStrLn $ "jack mean max:  " ++ show (maximum j)
  defaultMain
        [ bench "jackknife" (nf (jackknife  mean) rs)
        , bench "pjackknife (infinite spawn)" (nf (pjackknife (-1) mean) rs)
        , bench "pjackknife (d = 8)" (nf (pjackknife 8 mean) rs)
        , bench "rjackknife (infinite spawn)" (nf (rjackknife (-1) mean) rs)
        , bench "rjackknife (d = 8)" (nf (rjackknife 8 mean) rs)
        , bench "sjackknife" (nf (sjackknife mean) rs)
        , bench "parjackknife" (nf (sjackknife mean) rs)
        , bench "mergesort" (nf mergesort rs)
        , bench "parmerge 4"  (nf (parmerge 4) rs)
        , bench "parmerge 8"  (nf (parmerge 8) rs)
        , bench "parmerge 16" (nf (parmerge 16) rs)
        , bench "rmerge 4"  (nf (rmerge 4) rs)
        , bench "rmerge 8"  (nf (rmerge 8) rs)
        , bench "rmerge 16" (nf (rmerge 16) rs)
        ]
