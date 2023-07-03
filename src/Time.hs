{-# LANGUAGE GADTs #-}
{-# OPTIONS_GHC -Wno-unused-top-binds #-}


module Time (
    TimeSignature(..),
    Duration,
    measureDuration,
    Tempo(..),
    toSeconds,
    formatTime,
    isValidRMeasure
) where
import           Data.Ratio  ((%))
import           Text.Printf


type Duration = Rational

data Tempo where
  BPM :: Int -> Tempo
  deriving (Eq, Ord, Show)

data TimeSignature where
  TS :: {numerator :: Integer, denominator :: Integer}
          -> TimeSignature
  deriving (Eq, Ord, Show)

totalDuration :: [Duration] -> Duration
totalDuration = sum

durationRatio :: Duration -> Duration -> Rational
durationRatio d1 d2 = d1 / d2

measureDuration :: TimeSignature -> Duration
measureDuration (TS num denom) = num Data.Ratio.% denom

toSeconds :: Duration -> Tempo -> Double
toSeconds duration (BPM bpm) =  fromRational duration / (fromIntegral bpm / 60)


formatTime :: Double -> String
formatTime seconds =
  let totalMilliseconds = round (seconds * 1000)
      milliseconds = totalMilliseconds `mod` 1000
      totalSeconds = totalMilliseconds `div` 1000
      minutes = totalSeconds `div` 60
      remainingSeconds = totalSeconds `mod` 60
  in printf "%02d:%02d:%03d" (minutes :: Int) (remainingSeconds :: Int) (milliseconds :: Int)

data RMeasure where
  RMeasure :: {timeSignature :: TimeSignature,
                 durations :: [Duration]}
                -> RMeasure
  deriving (Eq, Show)

isValidRMeasure :: RMeasure -> Bool
isValidRMeasure (RMeasure ts ds) = sum ds == measureDuration ts

data TupletComponent = DurationComponent Duration | NestedTupletComponent Tuplet
  deriving (Eq, Show)

-- data Tuplet = Tuplet
--   { tupletMultiplier         :: Rational
--   , tupletDurations          :: [Either Duration Tuplet]
--   , tupletTotalDuration      :: Duration
--   , tupletMultipliedDuration :: Duration
--   }
--   deriving (Eq, Show)

data Tuplet = Tuplet
  { tupletMultiplier         :: Rational
  , tupletComponents         :: [TupletComponent]
  , tupletTotalDuration      :: Duration
  , tupletMultipliedDuration :: Duration
  }
  deriving (Eq, Show)

calculateTotalDuration :: [TupletComponent] -> Duration
calculateTotalDuration components =
  sum $ map calculateDuration components
  where
    calculateDuration (DurationComponent duration) = duration
    calculateDuration (NestedTupletComponent tuplet) = tupletTotalDuration tuplet * tupletMultiplier tuplet

createTuplet :: Rational -> [TupletComponent] -> Tuplet
createTuplet multiplier components =
  let totalDuration = calculateTotalDuration components
      multipliedDuration = totalDuration * multiplier
  in Tuplet multiplier components totalDuration multipliedDuration


{- TESTS -}

d :: Duration
d = 1 % 2

-- t :: Tempo
-- t = BPM 120

result :: Double
result = toSeconds d (BPM 120)

rm :: RMeasure
rm = RMeasure (TS 4 4) [d, d, d, d]

isValid :: Bool
isValid = isValidRMeasure rm


test1 :: IO ()
test1 = do
    let duration1 = 4 % 8
        duration2 = 5 % 8
        ratio = durationRatio duration1 duration2
    putStrLn $ "Duration ratio: " ++ show ratio

-- Duration ratio: 4 % 5


test2 :: IO ()
test2 = do
  let formatted = formatTime result
  putStrLn formatted

-- "00:00:250"


test3:: IO ()
test3 = do
  let innerTuplet = createTuplet (2 % 3) [DurationComponent (1 % 8), DurationComponent (1 % 8), DurationComponent (1 % 8)]
      components = [DurationComponent (1 % 8), NestedTupletComponent innerTuplet, DurationComponent (1 % 8), DurationComponent (1 % 8)]
      tuplet = createTuplet (4 % 5) components
  print tuplet

-- Tuplet {tupletMultiplier = 4 % 5, tupletComponents = [DurationComponent (1 % 8),NestedTupletComponent (Tuplet {tupletMultiplier = 2 % 3, tupletComponents = [DurationComponent (1 % 8),DurationComponent (1 % 8),DurationComponent (1 % 8)], tupletTotalDuration = 3 % 8, tupletMultipliedDuration = 1 % 4}),DurationComponent (1 % 8),DurationComponent (1 % 8)], tupletTotalDuration = 5 % 8, tupletMultipliedDuration = 1 % 2}

