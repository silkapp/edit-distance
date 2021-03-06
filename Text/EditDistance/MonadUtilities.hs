{-# LANGUAGE BangPatterns #-}

module Text.EditDistance.MonadUtilities where

{-# INLINE loopM_ #-}
loopM_ :: Monad m => Int -> Int -> (Int -> m ()) -> m ()
loopM_ from to action = go from to
  where
    go from to | from > to = return ()
               | otherwise = do action from
                                go (from + 1) to

-- foldM in Control.Monad is not defined using SAT style so optimises very poorly
{-# INLINE foldM #-}
foldM             :: (Monad m) => (a -> b -> m a) -> a -> [b] -> m a
foldM f a xs = foldr (\x rest a -> f a x >>= rest) return xs a
{-
-- If we define it like this, then we aren't able to deforest wrt. a "build" in xs, which would be sad :(
foldM f = go
  where go a (x:xs)  =  f a x >>= \fax -> go fax xs
        go a []      =  return a
-}

-- If we just use a standard foldM then our loops often box stuff up to return from the loop which is then immediately discarded
-- TODO: using this instead of foldM improves our benchmarks by about 2% but makes the code quite ugly.. figure out what to do
{-# INLINE foldMK #-}
foldMK             :: (Monad m) => (a -> b -> m a) -> a -> [b] -> (a -> m res) -> m res
foldMK f a xs k = foldr (\x rest a -> f a x >>= rest) k xs a