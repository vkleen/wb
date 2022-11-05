{-# LANGUAGE ImportQualifiedPost #-}

module Main where

import Plotting

import Control.Monad.Bayes.Class
import Control.Monad.Bayes.Sampler.Strict (sampler)
import Control.Monad.Bayes.Weighted (weighted)

import Control.Monad (replicateM, (>=>))
import Data.Text qualified as T

model :: MonadDistribution m => m (Double, Double)
model = do
  m1 <- uniform 90 110
  m2 <- uniform 70 100
  m3 <- uniform 100 120

  d1 <- uniform 0.4 0.6
  d2 <- uniform 0.9 1.1
  d3 <- uniform 0.4 1
  let cg   = d1*m1 + d2*m2 + d3*m3
      mass = m1 + m2 + m3
  pure (mass, cg)

main :: IO ()
main = do
  (sampler >=> plot) . replicateM 1_000 . fmap (, T.pack "sample") $
    model
