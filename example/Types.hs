{-# LANGUAGE AllowAmbiguousTypes       #-}
{-# LANGUAGE DeriveGeneric             #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE OverloadedStrings         #-}
{-# LANGUAGE TypeFamilies              #-}
{-# LANGUAGE RankNTypes #-}

module Types where

import           Data.Aeson
import           Data.Aeson.Types
import           Data.Hashable
import           Data.Maybe
import           Data.Text.Lazy
import qualified Data.Text.Lazy                    as TL
import           GHC.Generics
import           Network.HTTP.Conduit
import           Network.OAuth.OAuth2
import qualified Network.OAuth.OAuth2.TokenRequest as TR
import           Text.Mustache
import qualified Text.Mustache                     as M
import           URI.ByteString


-- dummy oauth2 request error
--
data Errors =
  SomeRandomError
  deriving (Show, Eq, Generic)

instance FromJSON Errors where
  parseJSON = genericParseJSON defaultOptions { constructorTagModifier = camelTo2 '_', allNullaryToStringTag = True }

data IDP =
    Douban
  | Dropbox
  | Facebook
  | Fitbit
  | Github
  | Google
  | Okta
  | StackExchange
  | Weibo
  deriving (Show, Eq, Generic)

instance Hashable IDP

idpFromText :: Text -> Maybe IDP
idpFromText ift = case TL.unpack $ TL.toLower ift of
  "okta"          -> Just Okta
  "github"        -> Just Github
  "google"        -> Just Google
  "douban"        -> Just Douban
  "dropbox"       -> Just Dropbox
  "facebook"      -> Just Facebook
  "fitbit"        -> Just Fitbit
  "weibo"         -> Just Weibo
  "stackexchange" -> Just StackExchange
  _               -> Nothing

newtype LoginUser =
  LoginUser { loginUserName :: Text
            } deriving (Eq, Show)

data IDPData = 
  IDPData { codeFlowUri :: Text
          , loginUser   :: Maybe LoginUser
          , idpName     :: IDP
          , oauth2Key   :: OAuth2
          , getAccessToken :: Manager -> OAuth2 -> ExchangeToken -> IO (OAuth2Result TR.Errors OAuth2Token)
          , getUserInfo :: Manager -> AccessToken -> IO (OAuth2Result Errors LoginUser)
          }

-- simplify use case to only allow one idp instance for now.
instance Eq IDPData where
  a == b = idpName a == idpName b

newtype TemplateData = TemplateData { idpData :: [IDPData]
                                 } deriving (Eq)

-- * Mustache instances
instance ToMustache IDPData where
  toMustache t' = M.object
    [ "codeFlowUri" ~> codeFlowUri t'
    , "isLogin" ~> isJust (loginUser t')
    , "user" ~> loginUser t'
    , "name" ~> show (idpName t')
    ]

instance ToMustache LoginUser where
  toMustache t' = M.object
    [ "name" ~> loginUserName t' ]

instance ToMustache TemplateData where
  toMustache td' = M.object
    [ "idps" ~> idpData td'
    ]
