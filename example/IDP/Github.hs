{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE QuasiQuotes   #-}

module IDP.Github where
import           Data.Aeson
import           Data.Aeson.Types
import           Data.Text.Lazy    (Text)
import           GHC.Generics
import           URI.ByteString
import           URI.ByteString.QQ
import           Data.Bifunctor
import           Network.OAuth.OAuth2
import           Network.HTTP.Conduit
import qualified Network.OAuth.OAuth2.TokenRequest as TR
import TokenUtil

import           Types

data GithubUser = GithubUser { name :: Text
                             , id   :: Integer
                             } deriving (Show, Generic)

instance FromJSON GithubUser where
    parseJSON = genericParseJSON defaultOptions { fieldLabelModifier = camelTo2 '_' }

userInfoUri :: URI
userInfoUri = [uri|https://api.github.com/user|]

toLoginUser :: GithubUser -> LoginUser
toLoginUser guser = LoginUser { loginUserName = name guser }

getUserInfo :: FromJSON a => Manager -> AccessToken -> IO (OAuth2Result a LoginUser)
getUserInfo mgr at = do
  re <- authGetJSON mgr at userInfoUri
  return (second toLoginUser re)

getAccessToken :: Manager
               -> OAuth2
               -> ExchangeToken
               -> IO (OAuth2Result TR.Errors OAuth2Token)
getAccessToken = getAT
