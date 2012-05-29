import Site                                  ( site, serve, redirectToSSL )
import Control.Concurrent                    ( forkIO, killThread )
import qualified Log                         as Log
import qualified DB.DB                       as DB
import Happstack.Server.SimpleHTTPS          ( nullTLSConf, tlsPort, tlsCert, tlsKey )
import Opts                                  ( getOptions, dbDir, httpPort, ssl, yoinkDir, tagDir, modDirs )
import System.Environment                    ( getArgs )

main :: IO ()
main = do
    args <- getArgs
    opts <- getOptions args
    Log.start
    db <- DB.newFromFile (dbDir opts)
    runMain (ssl opts) (httpPort opts) (yoinkDir opts) (tagDir opts) (modDirs opts) db

type WithSSL = Bool

runMain :: WithSSL -> Int -> FilePath -> FilePath -> [FilePath] -> DB.Database -> IO ()
runMain False port modLoaderDir tag dirs db = do
    tid <- forkIO $ do 
        Log.debugM  "Web server running. Press <enter> to exit."
        (serve (Right port) (site modLoaderDir tag dirs db))
    _ <- getLine
    killThread tid

runMain True port modLoaderDir tag dirs db = do
    let tlsconf = nullTLSConf { tlsPort = 8443, tlsCert = "testcert/server.crt", tlsKey = "testcert/server.key"}
    rtid <- forkIO (redirectToSSL tlsconf "localhost" port)
    tid <- forkIO $ do
        Log.debugM  "Web server running. Press <enter> to exit."
        serve (Left tlsconf)  (site modLoaderDir tag dirs db)
    _ <- getLine
    killThread rtid
    killThread tid
