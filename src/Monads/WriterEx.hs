module WriterEx where

{-|
   Author      : Sampath
   Maintainer  :
   File        : WriterEx
   Description : Examples using the Writer Monad
-}

import           Control.Monad.Writer
import qualified Data.Char            as C
-- import qualified Data.List            as L

----------------------------------------------------------------------
logNumber :: Int -> Writer [String] Int
logNumber x = writer (x, ["Got the number: " ++ show x])

multiply :: Writer [String] Int
multiply = do
    a <- logNumber 5
    b <- logNumber 6
    tell ["Now multiplying the numbers"]
    return (a * b)

----------------------------------------------------------------------
-- GCD of 2 numbers with logging
gcdx :: Int -> Int -> Writer [String] Int
gcdx a b
    | b == 0 = do
      tell ["Finished computing with " ++ show a]
      return a
    | otherwise = do
      tell [show a ++ " mod " ++ show b ++ " = " ++ show (a `mod` b)]
      gcdx b (a `mod` b)

-- λ> mapM_ print $ snd $ runWriter $ gcdx 1286 224
-- "1286 mod 224 = 166"
-- "224 mod 166 = 58"
-- "166 mod 58 = 50"
-- "58 mod 50 = 8"
-- "50 mod 8 = 2"
-- "8 mod 2 = 0"
-- "Finished computing with 2"

----------------------------------------------------------------------
--factorial with logging
fact :: Integer -> Writer [String] Integer
fact x
    | x <= 0 = do
      tell ["Computing the factorial of 0"]
      return 1
    | otherwise = do
      let t = x - 1
      tell ["recursing with x: " ++ show t]
      y <- fact t
      tell ["computing fact = " ++ show y]
      let s = x * y
      tell ["multiplied " ++ show x ++ " and " ++ show y]
      return s

-- factorial with Monoid
fact' :: Integer -> Writer (Sum Integer) Integer
fact' 0 = return 1
fact' n = do
    let t = n - 1
    tell $ Sum 1
    m <- fact' t
    let s = t * m
    tell $ Sum 1
    return s

----------------------------------------------------------------------
-- fibonacci series
fib :: Int -> Writer [String] Int
fib n = do
    tell ["fib " ++ show n ++ " invoked"]
    if n < 2
       then do
            tell ["fib " ++ show n ++ " = 1"]
            return 1
       else do
            a <- fib (n - 1)
            b <- fib (n - 2)
            tell ["fib " ++ show n ++ " = " ++ show (a + b)]
            return (a + b)

-- λ> mapM_ print $ snd $ runWriter (fib 3)
-- "fib 3 invoked"
-- "fib 2 invoked"
-- "fib 1 invoked"
-- "fib 1 = 1"
-- "fib 0 invoked"
-- "fib 0 = 1"
-- "fib 2 = 2"
-- "fib 1 invoked"
-- "fib 1 = 1"
-- "fib 3 = 3"
----------------------------------------------------------------------
-- Collatz Sequence
collatzSeq :: Integer -> Writer [Integer] Integer
collatzSeq n = do
    m <- collatz n
    if m == 1
       then return 1
       else collatzSeq m

collatz :: Integer -> Writer [Integer] Integer
collatz n
    | n == 1 = do
      tell [n]
      -- tell ["computing with n: " ++ show n]
      return 1
    | even n = do
      tell [n]
      -- tell [show n ++  " is even, computing " ++ show n ++ " div 2"]
      return (n `div` 2)
    | otherwise = do
      tell [n]
      -- tell [show n ++  " is odd, computing (3 * " ++ show n ++ " + 1)"]
      return (3 * n + 1)

----------------------------------------------------------------------
--
-- Towers Of Hanoi
--
--       ==        ||        ||
--      ====       ||        ||
--     ======      ||        ||
--    --------  --------  --------
--       A         B         C

data Pole = A | B | C deriving (Show)

-- 3 poles are as follows
-- Source      src
-- Destination target
-- Auxilliary  aux
--
toh :: Pole -> Pole -> Pole -> Int -> Writer [String] Int
toh src aux target n
    | n == 1 = writer (1, [show src ++ " -> " ++ show target])
    | otherwise = do
      -- move the top n-1 pegs from source to auxilliary via target
      x <- toh src target aux (n - 1)
      -- move the nth peg from source to target which is a single peg
      toh src aux target 1
      -- move the (n-1) pegs from auxilliary to target via source
      y <- toh aux src target (n - 1)
      -- Now return the moves completed
      return (1 + x + y)

-- visualizing the moves
showMoves :: (Int, [String]) -> IO ()
showMoves (n, moves) = do
    putStrLn "--------"
    putStrLn $ "Solved the TOH with " ++ show n ++ " moves!!!"
    -- putStrLn $ L.intercalate ", " moves
    mapM_ print moves
    putStrLn "--------"

hanoi :: Int -> IO ()
hanoi n = showMoves $ runWriter (toh A B C n)

-- λ> hanoi 3
-- --------
-- Solved the TOH with 7 moves!!!
-- "A -> C"
-- "A -> B"
-- "C -> B"
-- "A -> C"
-- "B -> A"
-- "B -> C"
-- "A -> C"
--  --------
----------------------------------------------------------------------
-- powers of a number
binPow :: Int -> Int -> Writer String Int
binPow 0 _ = return 1
binPow n x
    | even n = binPow (n `div` 2) x >>= \y ->
               tell ("Square " ++ show y ++ "\n") >>
               return (y * y)
    | otherwise = binPow (n - 1) x >>= \y ->
               tell ("Multiply " ++ show x ++ " and " ++ show y ++ "\n") >>
               return (x * y)

showPow :: IO ()
showPow = putStrLn $ execWriter $ binPow 3 2 >> binPow 3 7

-- λ> showPow
-- Multiply 2 and 1
-- Square 2
-- Multiply 2 and 4
-- Multiply 7 and 1
-- Square 7
-- Multiply 7 and 49
----------------------------------------------------------------------

changeLogCase :: Char -> Bool -> ((Char, Bool), String)
changeLogCase c b
    | b         = ((C.toLower c, False), "Lower ")
    | otherwise = ((C.toUpper c, True), "Upper ")

-- construct a Writer on the result of the function
logCase :: Char -> Bool -> Writer String (Char, Bool)
logCase c b = writer (changeLogCase c b)

----------------------------------------------------------------------
-- Inside a Writer you can't inspect what has been written, until you run
-- (or "unwrap") the  monad, using execWriter or  runWriter. However, you
-- can use  listen to inspect what  some sub-action wrote to  the writer,
-- before the value is appended to the writer state, and you can use pass
-- to modify what is written.
--
-- Ex: Log an action only if the log produced by the Writer satisifies a
-- predicate condition.
--
deleteOn :: (Monoid w) => (w -> Bool) -> Writer w a -> Writer w a
deleteOn predicate m = pass $ do
    (a, w) <- listen m
    if predicate w
       then return (a, id)
       else return (a, const mempty)

-- 2nd way
deletedOn :: (Monoid w) => (w -> Bool) -> Writer w a -> Writer w a
deletedOn predicate m = pass $ do
          a <- m
          return (a, \w -> if predicate w then mempty else w)

logTwo :: Writer [String] ()
logTwo = do
       deleteOn ((> 5) . length . head) $ tell ["basket"]
       deletedOn ((> 5) . length . head) $ tell ["ball"]
       deleteOn ((== 3) . length . head) $ tell ["pie"]

-- λ>runWriter logTwo
-- ((),["basket"])
-- --------------------------------------------------------------------
-- Monad  stack for  the application  uses  IO, wrapped  in a  logging
-- Writer    Using    WriterT    Writer    transformation    as    per
-- http://stackoverflow.com/questions/7630350/writer-vs-writert-in-haskell
-- The difference  is that  Writer is  a monad,  whereas WriterT  is a
-- monad transformer, i.e.  you give it some underlying  monad, and it
-- gives you  back a new monad  with "writer" features on  top. If you
-- only need the writer-specific features, use Writer.  If you need to
-- combine its effects with some other monad, such as IO, use WriterT.
--

type App a = WriterT [String] IO a

-- utility to write to the log
logMsg :: String -> App ()
logMsg msg = tell [msg]

-- get an input from the user and log the same
getUserInput :: App Int
getUserInput = do
    logMsg "getting the user data"
    m <- liftIO getLine
    logMsg $ "got line: " ++ show m
    (return . read) m

-- Use getUserInput and increment the result by 9
app :: App Int
app = do
    m <- getUserInput
    return (m + 9)

-- Now, for some reason inside app the we want to know what messages getUserInput
-- wrote to the log. We can do that with listen function
app' :: App Int
app' = do
    (m, logm) <- listen getUserInput
    let numLogLines = length logm
    logMsg $ "getUserInput logged the message " ++ show numLogLines ++ " lines"
    return (m + 1)

-- Main method for running and printing the log
main :: IO ()
main = do
    (res, logm) <- runWriterT app
    print $ "Result: " ++ show res
    putStrLn "Log: "
    mapM_ putStrLn logm

