{-# LANGUAGE OverloadedStrings, ScopedTypeVariables #-}

module Site where

import Control.Monad.Trans                   ( liftIO, lift )
import Data.Acid                             ( AcidState )
import Char                                  ( chr )
import Control.Monad.Error                   ( runErrorT, throwError )
import Control.Monad                         ( liftM )

import qualified Data.ByteString.Lazy        as B
import qualified Account                     as A
import qualified Codec.Binary.Url            as Url
import qualified Text.JSON                   as JS
import Happstack.Lite
import ServerError

checkUser ::  AcidState A.Database -> ServerPart Response
checkUser db = do 
   method GET
   rv <- runErrorT $ do 
      cookie <- lift $ lookCookieValue "token"
      let
            checkMaybe Nothing = throwError CookieDecode
            checkMaybe (Just aa) = return aa
      token <- checkMaybe $ liftM B.pack $ Url.decode cookie
      uid <- A.rethrowIO $ A.cookieToUser db token
      let msg = "Thanks for comming back " ++ (toS uid)
      liftIO $ putStrLn msg 
      return $ JS.encode $ JS.toJSString msg
   rsp $ rv

getUser ::  AcidState A.Database -> ServerPart Response
getUser db = do 
   method POST
   uid <- lookBS "email"
   pwd <- lookBS "password"
   let 

         ifexists ll bb = do ll' <- ll
                             ifexists' ll' bb
         ifexists' (Left UserAlreadyExists) bb = bb
         ifexists' (Left ee)  _   = return (Left ee)
         ifexists' (Right vv) _   = return (Right vv)

         addUser = runErrorT $ do 
            A.rethrowIO $ A.addUser db (uid) (pwd)
            token <- A.rethrowIO $ A.loginToCookie db (uid) (pwd)
            let msg = "Thank you for registering " ++ (toS uid)
            liftIO $ putStrLn msg 
            let cookie = mkCookie "token" (Url.encode (B.unpack token))
            lift $ addCookies [(Session, cookie)]
            return $ JS.encode $ JS.toJSString msg
         loginUser = runErrorT $ do 
            token <- A.rethrowIO $ A.loginToCookie db (uid) (pwd)
            let msg = "Welcome Back " ++ (toS uid)
            liftIO $ putStrLn msg 
            let cookie = mkCookie "token" (Url.encode (B.unpack token))
            lift $ addCookies [(Session, cookie)]
            return $ JS.encode $ JS.toJSString msg

   rv <- addUser `ifexists` loginUser
   rsp $ rv

rsp :: (ToMessage a1, Show a) => Either a a1 -> ServerPart Response
rsp (Left ee) = internalServerError $ toResponse $ JS.encode $ JS.toJSString (show ee)
rsp (Right msg) = ok $ toResponse msg

toS :: B.ByteString -> String
toS ss = map (chr . fromIntegral) $ B.unpack ss


