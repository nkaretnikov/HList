module Main where

import Control.Exception
import System.FilePath
import Test.Hspec
import System.Process
import System.Exit
import System.Directory
import Data.Maybe
import Control.Monad

main = do

  es <- getDirectoryContents "examples"


  print es
  -- very dumb
  es <- filterM (\e -> allM
    [return (takeExtension e == ".hs"),
     doesFileExist (dropExtension ("examples"</>e) ++ ".ref") ]) es

  print es

  hspec $ do
    mapM_ runghcwith es


runghcwith f = describe f $ it "ok" $ checkResult $
  do
    let ex = ("examples" </>)
    let inFile = ex (takeBaseName f)
        outFile = dropExtension inFile ++ ".out"
        refFile = dropExtension inFile ++ ".ref"

    (ec, stdout, stderr) <- readProcessWithExitCode "cabal" ["repl","-v0",
        "--ghc-options", "-w -fcontext-stack=50 -iexamples -v0 "]
        (":load " ++ inFile ++ "\nmain")

    writeFile outFile stdout

    ofe <- doesFileExist refFile
    diff <- if ofe then fmap Just $
        readProcess "diff" ["-b", outFile, refFile] "" else return Nothing

    return (ec, stderr, diff)
 where
  checkResult io = io `shouldReturn` (ExitSuccess, "", Just "")



allM [] = return True
allM (x:xs) = do
    x <- x
    if x then allM xs else return False