{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE QuasiQuotes   #-}

module IDP.Okta where
import           Data.Aeson
import           Data.Aeson.Types
import           Data.Text.Lazy    (Text)
import           GHC.Generics
import           Types
import           URI.ByteString
import           URI.ByteString.QQ
import           Data.Bifunctor
import           Network.OAuth.OAuth2
import           Network.HTTP.Conduit
import qualified Network.OAuth.OAuth2.TokenRequest as TR
import TokenUtil

data OktaUser = OktaUser { name              :: Text
                         , preferredUsername :: Text
                         } deriving (Show, Generic)

instance FromJSON OktaUser where
    parseJSON = genericParseJSON defaultOptions { fieldLabelModifier = camelTo2 '_' }

userInfoUri :: URI
userInfoUri = [uri|https://dev-148986.oktapreview.com/oauth2/v1/userinfo|]

toLoginUser :: OktaUser -> LoginUser
toLoginUser ouser = LoginUser { loginUserName = name ouser }

getUserInfo :: FromJSON a => Manager -> AccessToken -> IO (OAuth2Result a LoginUser)
getUserInfo mgr at = do
  re <- authGetJSON mgr at userInfoUri
  return (second toLoginUser re)

getAccessToken :: Manager
               -> OAuth2
               -> ExchangeToken
               -> IO (OAuth2Result TR.Errors OAuth2Token)
getAccessToken = getAT
