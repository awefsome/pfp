.. PFP Tutorial documentation master file, created by
   sphinx-quickstart on Thu Apr 26 18:13:23 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

par & pseq for parallel programming in Haskell!
===============================================

The functional programming language Haskell provides a very easy and explict way of parallelization. In this tutorial we are going to discuss following two functions which can be used for parallelization

-   **par**:

    `par` annotation (from Control.Parallel) is used to tell compiler, how best to parallelize the code.

    Consider *x `par` y* some kind of operation where x is forked in parallel and y is returned. It may sound bit strange but if you consider lazy evolution (an expression is evaluated when it is needed), it will make perfect sense.

    From the manual: **The expression (x `par` y) sparks the evaluation of x (to weak head normal form) and returns y. Sparks are queued for execution in FIFO order, but are not executed immediately. If the runtime detects that there is an idle CPU, then it may convert a spark into a real thread, and run the new thread on the idle CPU. In this way the available parallelism is spread amongst the real CPUs.**

-   **pseq**:

    pseq evaluates expression on the left strictly before it starts to evaluate expression on right.


By default GHC runs program on one processor. If you wish to run your program in parallel, you got to link your program with -threaded and RTS -n option where n is number of cores to be used. However, it wouldn't be beneficial alone to parallelize your program. You must provide some hint to compiler as well about how best to parallelize the code. Here we would be using par & pseq to do that.

par combinator (often used with pseq) is simplest way to expose parallelism to the compiler. Let's try parallelizing Mergesort and see how it performs when compared to sequential run:

Mergesort (sequential)::

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


Mergesort (par and pseq)::

    parmerge :: Ord a => Int -> [a] -> [a]
    parmerge d (x:[]) = [x]
    parmerge 0 xs     = mergesort xs
    parmerge d xs = par h (pseq t (merge h t))
        where
            h        = parmerge (d-1) hs
            t        = parmerge (d-1) ts
            (hs, ts) = splitAt (n `div` 2) xs
            n        = l + 1 * l `mod` 2
            l        = length xs


Benachmarking results with "-threaded -N8":

    .. image:: _static/benchmarks.png

Please note here in parallel merge sort, we are doing simple merge sorting after a depth d. This is important to ensure that you are creating sprking for small jobs. Otherwise, cost of creating a spark outweighs the cost of just evaluating it right away.
