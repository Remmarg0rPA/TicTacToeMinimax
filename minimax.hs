module AI where

import Data.List (transpose)
import Foreign.Marshal.Array (peekArray)
import Foreign.C.Types
import Foreign.Ptr


{-
The tic-tac-toe board is represented as a double array with Ints
P1 is represented with 1, P2 is represented with 2
0 indicates that the square is empty
-}


getValidMoves :: [[Int]] -> [(Int,Int)]
getValidMoves board = [ (x,y) | x <- [0..2], y <- [0..2], board!!y!!x == 0]


makeMove :: [[Int]] -> Int -> (Int,Int) -> [[Int]]
makeMove board p (x,y) = 
    [[if col==x && row==y then p else board!!row!!col 
        | col <- [0..2]] 
    | row <- [0..2]]


getDraw :: [[Int]] -> Bool
getDraw = (True `notElem`) . map (0 `elem`)


{-
1^3 = 3 P1 in a row = 1 and 2^3 = 3 P2 in a row = 8
No other combos can result in these products 
-}
getWinner :: [[Int]] -> Int
getWinner board =
    if 1 `elem` boardProducts
        then 1
    else if 8 `elem` boardProducts
        then 2
    else 0
    where rows = [ product row | row <- board]
          columns = [ product row | row <- transpose board]
          diagonals  = [board!!0!!0 * board!!1!!1 * board!!2!!2,  board!!0!!2 * board!!1!!1 * board!!2!!0]
          boardProducts = rows ++ columns ++ diagonals


-- Scores all of the boards
minimax_score :: [[Int]] -> Int -> Int -> Int
minimax_score board player aiPlayer = 
    if (winner /= 0)
        then
            (
            if (winner == aiPlayer)
                then 10
                else -10
            )
    else if (getDraw board)
        then 0
    else foldl1 (if player==aiPlayer then max else min) boardScores
    where
        winner = getWinner board
        validMoves = getValidMoves board
        otherPlayer = if player == 1 then 2 else 1
        move = makeMove board player
        boardScores = [ minimax_score (move mv) otherPlayer aiPlayer 
                        | mv <- validMoves]


-- Determines the best move based on the score of each board
minimax_ai :: [[Int]] -> Int -> (Int,Int)
minimax_ai board player = 
    let m = foldl1 max $ map fst boardScores in
        snd . head . dropWhile (\(sc,mv) -> (m > sc)) $ boardScores
    where
        ai = player
        validMoves = getValidMoves board
        otherPlayer = if player == 1 then 2 else 1
        move = makeMove board player
        score = \ mv -> (minimax_score (move mv) otherPlayer player)
        boardScores = [ (score mv, mv) | mv <- validMoves]


-------------------------------------------------------
-- Python-Haskell Interfaces
-------------------------------------------------------


{-
Encode data to be returned from Haskell func to Python 
A move is represented with a 2-digit number, for example 21 = (2,1)
-}
hsToPy :: (Int, Int) -> CInt
hsToPy (x,y) = fromIntegral (x*10 + y)


{-
Decode data from Python func call
The board is bassed as an array of CInts with length 10:
0-2: row 1
3-5: row 2
6-8: row 3
9: current player
-}
pyToHs :: Ptr CInt -> IO ([[Int]], Int)
pyToHs arrPtr = do
    pyData <- peekArray 10 arrPtr
    let board = [          take 3 pyData, 
                take 3 . drop 3 $ pyData,
                take 3 . drop 6 $ pyData
            ]
    let player = last pyData
    return (map (map fromIntegral) board, fromIntegral player)


{-
Python's interface with Haskell AI
The board has to be passed as explained above the "pyToHs"-func
The return value is a number as explained above the "hsToPy"-func
-}
minimax_ai_hs :: Ptr CInt -> IO CInt
minimax_ai_hs arrPtr = do
    (board, player) <- pyToHs arrPtr    
    let mv = minimax_ai board player
    return $ hsToPy mv


-- Python's interface with getWinner
getWinner_hs :: Ptr CInt -> IO CInt
getWinner_hs ptr = do
    (board, player) <- pyToHs ptr    
    return . fromIntegral $ getWinner board


foreign export ccall minimax_ai_hs :: Ptr CInt -> IO CInt
foreign export ccall getWinner_hs :: Ptr CInt -> IO CInt