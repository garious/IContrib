{-# LANGUAGE TypeFamilies, DeriveDataTypeable, TemplateHaskell #-}
{-# OPTIONS_GHC -fspec-constr-count=2 -fno-warn-orphans #-}
module Account where

import Control.Monad.IO.Class                ( MonadIO )
import Data.Word                             ( Word8 )
import Monad                                 ( liftM )
import Control.Monad.State                   ( get, put )
import Control.Monad.Reader                  ( ask )
import Control.Monad.Error                   ( runErrorT, throwError, MonadError, liftIO)
import Data.Typeable                         ()
import qualified Data.Map                    as Map
import qualified Crypto.Hash.SHA512          as SHA512
import qualified Data.ByteString.Lazy        as BL
import qualified Data.ByteString             as BS
import Data.Acid
import Data.SafeCopy
import Random(randomIO, Random, random, randomR)
import ServerError

type UserID    = BL.ByteString
type Password  = BL.ByteString
type Cookie    = BL.ByteString

type Hash      = BS.ByteString
type Salt      = BS.ByteString

data PasswordHash = PasswordHash Hash Salt
$(deriveSafeCopy 0 'base ''PasswordHash)

data Database = Database { users :: (Map.Map UserID PasswordHash) 
                         , userCookies :: (Map.Map UserID Cookie)
                         , cookies :: (Map.Map Cookie UserID)
                         }
$(deriveSafeCopy 0 'base ''Database)

empty :: Database
empty = Database Map.empty Map.empty Map.empty

addUserU :: UserID -> PasswordHash -> Update Database (Either ServerError ())
addUserU uid phash = runErrorT $ do
   db <- get
   case(Map.lookup uid (users db)) of
      Nothing -> put $ db { users = (Map.insert uid phash (users db)) }
      (Just _) -> throwError UserAlreadyExists

maybeE :: MonadError e m => e -> Maybe a -> m a
maybeE _ (Just a) = return a
maybeE ee _       = throwError ee

cookieToUserQ :: Cookie -> Query Database (Either ServerError UserID)
cookieToUserQ cookie = runErrorT $ do
   db <- ask
   maybeE BadCookie (Map.lookup cookie (cookies db))

listUsersQ :: Query Database [UserID]
listUsersQ = do
   db <- ask
   return $ map fst $ Map.toList (users db)

addUserCookieU :: UserID -> Cookie -> Update Database ()
addUserCookieU uid cookie = do
   db <- get
   put $ db { cookies = (Map.insert cookie uid (cookies db)) 
            , userCookies = (Map.insert uid cookie (userCookies db))
            }

clearUserCookieU :: UserID -> Update Database ()
clearUserCookieU uid = do
   db <- get
   case (Map.lookup uid (userCookies db)) of
      Nothing -> return ()
      (Just cc) -> put $ db { cookies = (Map.delete cc (cookies db))
                            , userCookies = (Map.delete uid (userCookies db))
                            }

checkPasswordQ :: UserID -> Password -> Query Database (Either ServerError ())
checkPasswordQ uid pwd = runErrorT $ do
   db <- ask
   let checkPass Nothing = throwError UserDoesntExist
       checkPass (Just (PasswordHash hash salt)) 
         | hash == hashPassword salt pwd = return $ ()
       checkPass _ = throwError BadPassword
   checkPass (Map.lookup uid (users db))

hashPassword :: Salt -> Password -> Hash
hashPassword salt pwd = (iterate step pwdS) !! iterationCount
    where iterationCount = 100
          pwdS = toS pwd
          step chain = SHA512.hash (chain `BS.append` salt)

toS :: BL.ByteString -> BS.ByteString
toS = BS.concat . BL.toChunks


$(makeAcidic ''Database ['addUserU, 'checkPasswordQ, 'addUserCookieU, 'cookieToUserQ, 'listUsersQ, 'clearUserCookieU ])

listUsers :: AcidState Database ->  IO [UserID]
listUsers db = query db ListUsersQ


addUser :: AcidState Database -> UserID -> Password -> IO (Either ServerError ())
addUser db uid pwd = do
   salt <- newSalt
   update db (AddUserU uid (PasswordHash (hashPassword salt pwd) salt))

rethrowIO :: (MonadError e m, MonadIO m) => IO (Either e b) -> m b
rethrowIO aa = do
   err <- liftIO aa
   case(err) of
      (Left ee)   -> throwError ee
      (Right val) -> return val
   
loginToCookie :: AcidState Database -> UserID -> Password -> IO (Either ServerError Cookie) 
loginToCookie db uid pwd = runErrorT $ do
   _ <- rethrowIO $ query db (CheckPasswordQ uid pwd)
   cookie <- liftIO $ newCookie
   _ <- liftIO $ update db (AddUserCookieU uid cookie)
   return cookie

cookieToUser :: AcidState Database -> Cookie -> IO (Either ServerError UserID)
cookieToUser db cookie = query db (CookieToUserQ cookie)

clearUserCookie :: AcidState Database -> UserID -> IO ()
clearUserCookie db uid = update db (ClearUserCookieU uid)

instance Random Word8 where
    randomR (lo, hi) rng = let (val, rng') = randomR (fromIntegral lo, fromIntegral hi) rng
                               val :: Int
                           in  (fromIntegral val, rng')
    random rng = randomR (minBound, maxBound) rng
 
newSalt :: IO BS.ByteString
newSalt = liftM BS.pack $ sequence $ take 32 $ repeat randomIO

newCookie :: IO BL.ByteString
newCookie = liftM BL.pack $ sequence $ take 32 $ repeat randomIO



