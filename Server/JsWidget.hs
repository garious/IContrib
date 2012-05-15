{-# LANGUAGE OverloadedStrings #-}

module JsWidget where

import Control.Monad                         ( msum )
import Happstack.Server                      ( ServerPart, Response, path, nullDir, lookPairs, ok, toResponse )
import Happstack.Server.Routing              ( trailingSlash )

import System.Directory
import System.FilePath
import Control.Monad                         ( guard )
import Control.Monad.Trans                   ( liftIO )
import Data.List                             ( intercalate )
import           Text.Blaze ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import qualified Text.JSON                   as JS
import qualified Data.Text.Lazy as T

-- Is this a javascript file or directory within a widgets directory?
widget :: FilePath -> [String] -> ServerPart Response
widget root baseUrl = msum [
      path (\p -> jsModFile root baseUrl (p ++ ".js"))
    , jsMod root baseUrl
    , path (\p -> widget root (baseUrl ++ [p]))
    ]

-- Is there a javascript file named 'Index.js' within this directory?
jsMod :: FilePath -> [String] -> ServerPart Response
jsMod root baseUrl = do
      nullDir
      trailingSlash
      jsModFile root baseUrl "Index.js"

-- Is there a javascript file here? 
jsModFile :: FilePath -> [String] -> FilePath -> ServerPart Response
jsModFile root baseUrl filename = do
      nullDir
      b <- liftIO (doesFileExist (joinPath (root : url)))
      guard b
      ps <- lookPairs
      let ps' = [(s, x) | (s, Right x) <- ps]
      ok (toResponse (htmlForJsMod baseUrl ('/' : mkPath url) (JS.toJSObject ps')))
   where
      url = baseUrl ++ [filename]

htmlForJsMod :: [String] -> String -> JS.JSObject String -> H.Html
htmlForJsMod baseUrl filename ps = appTemplate $ do
      H.script ! A.src yoinkAttr  ! A.type_ "text/javascript" $ ""
      H.script ! A.src preloadedAttr  ! A.type_ "text/javascript" $ ""
      H.script ! A.type_ "text/javascript" $ H.toHtml (T.pack yoink)
  where
      yoinkAttr = H.toValue (mkPath (mkRelUrl baseUrl ["Yoink.js"]))
      preloadedAttr = H.toValue (mkPath (mkRelUrl baseUrl ["WebApp.js"]))

      yoink = "\n\
           \YOINK.setDebugLevel(1);\n\
           \YOINK.resourceLoader('', {}, window.PRELOADED_MODULES).getResources([\n\
           \    '/Tag/Interface.js',\n\
           \    '/Tag/ToDom.js',\n\
           \    '/Tag/Webpage.js',\n\
           \    {path: '" ++ filename ++ "', params: " ++ params ++ "}\n\
           \], function(Iface, Dom, Webpage, widget) {\n\
           \    var page = Iface.getInterface(widget, Webpage.webpageId);\n\
           \    if (page) {\n\
           \        var title = page.getTitle(widget);\n\
           \        if (title) {\n\
           \            document.title = title;\n\
           \        }\n\
           \    }\n\
           \    var iface = Iface.getInterface(widget, Dom.toDomId);\n\
           \    var nd = iface ? iface.toDom(widget) : widget;\n\
           \    document.body.appendChild(nd);\n\
           \});\n"

      params = JS.encode ps


 

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
     H.docTypeHtml $ do
       H.head $ do
         H.meta ! A.httpEquiv "Content-Type" ! A.content "text/html;charset=utf-8"
       H.body ! A.style "margin: 0; padding: 0" $ body

