# Copyright 2013 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'google/api_client'
require 'google/api_client/client_secrets'
require './credentials_store'

# These utility functions are an example of how Ruby code can use the
# Google::APIClient class to authorize access to an application using OAuth2.
# The code below is not an official client library, but rather an example of
# how to use OAuth2. Feel free to modify or rewrite it to fit the specific
# needs of your application.

SCOPES = [
    'https://www.googleapis.com/auth/glass.timeline',
    'https://www.googleapis.com/auth/glass.location',
    'https://www.googleapis.com/auth/userinfo.profile'
]

##
# Error raised when an error occurred while retrieving credentials.
class GetCredentialsError < StandardError
  ##
  # Initialize a NoRefreshTokenError instance.
  #
  # @param [String] authorize_url
  #   Authorization URL to redirect the user to in order to in order to
  #   request offline access.
  def initialize(authorization_url)
    @authorization_url = authorization_url
  end

  def authorization_url=(authorization_url)
    @authorization_url = authorization_url
  end

  def authorization_url
    return @authorization_url
  end
end

##
# Error raised when a code exchange has failed.
class CodeExchangeError < GetCredentialsError
end

##
# Error raised when no refresh token has been found.
class NoRefreshTokenError < GetCredentialsError
end

##
# Error raised when no user ID could be retrieved.
class NoUserIdError < StandardError
end

##
# Loads client_secrets.json and returns authorization credentials with
# the data from that file.
#
# @return [Signet::OAuth2::Client]
#   OAuth 2.0 credentials.
def client_secrets
  Google::APIClient::ClientSecrets.load(
    'client_secrets.json').to_authorization
end

##
# Exchange an authorization code for OAuth 2.0 credentials.
#
# @param [String] auth_code
#   Authorization code to exchange for OAuth 2.0 credentials.
# @return [Signet::OAuth2::Client]
#   OAuth 2.0 credentials.
def exchange_code(authorization_code)
  client = Google::APIClient.new
  client.authorization = client_secrets
  client.authorization.code = authorization_code

  begin
    client.authorization.fetch_access_token!
    return client.authorization
  rescue Signet::AuthorizationError
    raise CodeExchangeError.new(nil)
  end
end

##
# Send a request to the UserInfo API to retrieve the user's information.
#
# @param [Signet::OAuth2::Client] credentials
#   OAuth 2.0 credentials to authorize the request.
# @return [Google::APIClient::Schema::Oauth2::V2::Userinfo]
#   User's information.
def get_user_info(credentials)
  client = Google::APIClient.new
  client.authorization = credentials
  oauth2 = client.discovered_api('oauth2', 'v2')
  result = client.execute!(:api_method => oauth2.userinfo.get)  
  user_info = nil

  if result.success?
    user_info = result.data
  else
    puts "An error occured: #{result.data['error']['message']}"
  end

  if user_info != nil && user_info.id != nil
    return user_info
  end

  raise NoUserIdError, "Unable to retrieve the user's Google ID."
end

##
# Retrieve authorization URL.
#
# @param [String] user_id
#   User's Google ID.
# @param [String] state
#   State for the authorization URL.
# @return [String]
#   Authorization URL to redirect the user to.
def get_authorization_url(user_id, state)
  client = Google::APIClient.new
  client.authorization = client_secrets
  client.authorization.scope = SCOPES

  return client.authorization.authorization_uri(
    approval_prompt: :force,
    access_type: :offline,
    user_id: user_id,
    state: state
  ).to_s
end

##
# Retrieve credentials using the provided authorization code.
#
#  This function exchanges the authorization code for an access token and
#  queries the UserInfo API to retrieve the user's Google ID.
#  If a refresh token has been retrieved along with an access token, it is
#  stored in the application database using the user's Google ID as key.
#  If no refresh token has been retrieved, the function checks in the
#  application database for one and returns it if found or raises a
#  NoRefreshTokenError with an authorization URL to redirect the user to.
#
# @param [String] auth_code
#   Authorization code to use to retrieve an access token.
# @param [String] state
#   State to set to the authorization URL in case of error.
# @return [Signet::OAuth2::Client]
#   OAuth 2.0 credentials containing an access and refresh token.
def get_credentials(authorization_code, state)
  user_id = ''
  begin
    credentials = exchange_code(authorization_code)
    user_info = get_user_info(credentials)
    user_id = user_info.id
    if credentials.refresh_token != nil
      store_credentials(user_id, credentials)
      return credentials
    else
      credentials = get_stored_credentials(user_id)
      if credentials != nil && credentials.refresh_token != nil
        return credentials
      end
    end
  rescue CodeExchangeError => error
    print 'An error occurred during code exchange.'
    # Glass services should try to retrieve the user and credentials
    # for the current session.
    # If none is available, redirect the user to the authorization URL.
    error.authorization_url = get_authorization_url(user_id, state)
    raise error
  rescue NoUserIdError
    print 'No user ID could be retrieved.'
  end
  authorization_url = get_authorization_url(user_id, state)
  raise NoRefreshTokenError.new(authorization_url)
end
