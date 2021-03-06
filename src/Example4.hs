{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
module Example4 where

{-|
   Author      : Sampath
   Maintainer  :
   File        : Example4.hs
   Description : Various Example problems
-}

----------------------------------------------------------------------
import           Control.Monad
import           Data.Aeson
import           Data.Aeson.Encode.Pretty
import qualified Data.ByteString.Lazy     as BL
import qualified Data.Char                as C
import qualified Data.Text                as T
import           Data.Text.Encoding
import           GHC.Generics

----------------------------------------------------------------------
-- implementation of Pascals triangle
--
binomialCoefficients :: (Num a) => [a] -> [a]
binomialCoefficients xs = zipWith (+) (0 : xs) (xs ++ [0])

pascalsRows :: (Num a) => [[a]]
pascalsRows = iterate binomialCoefficients [1]

pascalsTriangle :: Int -> IO ()
pascalsTriangle n = mapM_ print $ take n pascalsRows
----------------------------------------------------------------------
-- return all positions of a value in list
positions :: Eq a => a -> [a] -> [Int]
positions x xs = [i | (y, i) <- zip xs [0 .. n], x == y]
                 where
                 n = length xs - 1

-- λ> positions 0 [1,0,0,0,1,1,1,0,1]
-- [1,2,3,7]
----------------------------------------------------------------------
-- parsing different types of terms
-- parsing data into hex values, decimal values and words containing
-- only alpha-numeric characters
--
data ParsedData = Digit Integer
                | Hex Integer
                | Word String
                deriving (Show)

-- adding character to the parsed Hex digit
parseHexDigit :: ParsedData -> Char -> [ParsedData]
parseHexDigit (Hex n) c = if C.isHexDigit c
                             then return (Hex ((n * 16) + toInteger (C.digitToInt c)))
                             else mzero
parseHexDigit _ _       = mzero

-- adding character to the parsed decimal digit
parseDigit :: ParsedData -> Char -> [ParsedData]
parseDigit (Digit n) c = if C.isDigit c
                            then return (Digit ((n * 10) + toInteger (C.digitToInt c)))
                            else mzero
parseDigit _ _         = mzero

-- adding character to the parsed Word
parseWord :: ParsedData -> Char -> [ParsedData]
parseWord (Word w) c = if C.isAlpha c
                          then return (Word (w ++ [c]))
                          else mzero
parseWord _ _        = mzero

-- parse the digit as Hex, Decimal and Word
--
parse :: ParsedData -> Char -> [ParsedData]
parse p c = parseHexDigit p c `mplus`
            parseDigit p c `mplus`
            parseWord p c

-- parse an entire String and return a list of the possible parsed values
--
parseArgs :: String -> [ParsedData]
parseArgs str = do
          xinit <- return (Hex 0) `mplus`
                  return (Digit 0) `mplus`
                  return (Word "")
          foldM parse xinit str
----------------------------------------------------------------------
-- JSON pretty printing example
data Person = Person { firstName :: String
                     , lastName  :: String
                     , id        :: Int
                     } deriving (Show, Generic)

instance ToJSON Person
instance FromJSON Person

process :: IO String
process = getLine

-- convert lazy bytestring into a regular string
getJSON :: ToJSON a => a -> String
getJSON = T.unpack . decodeUtf8 . BL.toStrict . encodePretty

-- pretty print json
pjson :: IO ()
pjson = do
    putStrLn "First Name"
    fName <- process
    putStrLn "Last Name"
    lName <- process
    putStrLn "Id"
    i <- process

    let person = Person fName lName (read i)
    -- print (encodePretty person)
    putStrLn (getJSON person)
    return ()

-- λ> pjson
-- First Name
-- Mickey
-- Last Name
-- Mouse
-- Id
-- 123
-- {
--     "lastName": "Mouse",
--     "firstName": "Mickey",
--     "id": 123
-- }
----------------------------------------------------------------------
-- Pairs
----------------------------------------------------------------------
newtype Pair = Pair (Int, Int) deriving (Eq)

-- Pair as an instance of the Num
instance Num Pair where
  Pair (a, b) + Pair (c, d) = Pair (a + b, c + d)
  Pair (a, b) - Pair (c, d) = Pair (a - b, c - d)
  Pair (a, b) * Pair (c, d) = Pair (a * b, c * d)
  negate (Pair (a, b))      = Pair (-a, -b)
  abs (Pair (a, b))         = Pair (abs a, abs b)
  fromInteger 0             = Pair (0, 0)

-- λ> 0 :: Pair
-- (0, 0)
-- λ> (0 :: Pair) > 0
-- False

-- Pair as an instance of the Ord
instance Ord Pair where
  Pair (a, b) > 0 = min a b > 0 && max a b > 0
  Pair (a, b) < 0 = min a b < 0 && max a b < 0
  -- Pair (a, b) `compare` Pair (c, d) = (a `compare` c) && (b `compare` d)


-- Pair as an instance of the Show
instance Show Pair where
  show (Pair (a, b)) = "(" ++ show a ++ ", " ++ show b ++ ")"

posEqn :: Int -> Int -> [Pair]
posEqn x y
  | x < 0 || y < 0 = []
  | otherwise = tail [Pair (a, b) | a <- [0 .. x], b <- [0 .. y]]

-- λ> posEqn 2 3
-- [(0, 1),(0, 2),(0, 3),(1, 0),(1, 1),(1, 2),(1, 3),(2, 0),(2, 1),(2, 2),(2, 3)]
-- λ> posEqn 0 0
