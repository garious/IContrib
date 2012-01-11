{-# LANGUAGE OverloadedStrings #-}

module JsWidget where

import Happstack.Lite

import System.Directory
import System.FilePath
import Control.Monad                         ( guard )
import Control.Monad.Trans                   ( liftIO )
import Control.Applicative                   ( optional )
import Data.List                             ( intercalate )
import           Text.Blaze ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import qualified Data.Text.Lazy as T

-- Is this a javascript file or directory within a widgets directory?
widget :: FilePath -> [String] -> ServerPart Response
widget root baseUrl = msum [
      nullDir >> jsMod root baseUrl
    , path (\p -> widget root (baseUrl ++ [p]))
    ]

-- Is this a javascript file within a widgets directory?
jsMod :: FilePath -> [String] -> ServerPart Response
jsMod root baseUrl = do
      maybeFile <- optional (lookText "filename")
      let filename = maybe "index.js" T.unpack maybeFile
          url = baseUrl ++ [filename]
      b <- liftIO (doesFileExist (joinPath (root : url)))
      guard b
      maybeNm <- optional (lookText "main")
      ok (toResponse (htmlForJsMod baseUrl filename (fmap T.unpack maybeNm)))

htmlForJsMod :: [String] -> String -> Maybe String -> H.Html
htmlForJsMod baseUrl filename maybeNm = appTemplate $ do
--      H.link ! A.rel "stylesheet" ! A.type_ "text/css" ! A.media "all" ! A.href nineAttr
      H.script ! A.src yoinkAttr  ! A.type_ "text/javascript" $ ""
      H.script ! A.type_ "text/javascript" $ H.toHtml (T.pack yoink)
  where
--      nineAttr = H.toValue (mkPath (mkRelUrl baseUrl ["css", "960.css"]))
      yoinkAttr = H.toValue (mkPath (mkRelUrl baseUrl ["yoink", "yoink.js"]))

      yoink = "\n(function(){\n"
           ++ "function recurse(ldr, node, callback) {\n"
           ++ "    if (node && node.deps && node.callback) {\n"
           ++ "        ldr.getResources(node.deps, function(nd) {recurse(ldr, node.callback(nd), callback);})\n"
           ++ "    } else {\n"
           ++ "        callback(node);\n"
           ++ "    }\n"
           ++ "}\n"
           ++ "var loader = YOINK.resourceLoader();\n"
           ++ "loader.getResources(['" ++ filename ++ "'], function(M) {\n    "
           ++ setTitle
           ++ reassign
           ++ "var node = typeof M === 'function' ? M() : M;\n"
           ++ "recurse(loader, node, function(nd) {document.body.appendChild(nd)});\n"
           ++ "});\n"
           ++ "})()\n"

      setTitle = "if (M.title) { document.title = M.title; };\n    "

      reassign = "M = " ++ (maybe "M.main || M" (\nm -> "M."++nm) maybeNm) ++ ";\n    "
 

-- mkRelUrl ["a","b"] ["c","d"] == ["..","..","c","d"]
-- mkRelUrl ["a","b"] ["a","c"] == ["..","c"]
mkRelUrl :: [String] -> [String] -> [String]
mkRelUrl (x:xs) (y:ys) | x == y   = mkRelUrl xs ys 
mkRelUrl baseUrl url              = (replicate (length baseUrl) "..") ++ url

-- Path elements to URL with all forward slashes
mkPath :: [String] -> String
mkPath = intercalate "/"

appTemplate :: H.Html -> H.Html
appTemplate body =
     H.html $ do
       H.head $ do
         H.meta ! A.httpEquiv "Content-Type" ! A.content "text/html;charset=utf-8"
       H.body body
