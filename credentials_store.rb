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


require 'yaml'
require 'sqlite3'

# The functions in this file are called by those in oauth_utils.rb. This
# separates the OAuth2 portion of the code from the app-specific portion
# that decides where and how user credentials should be stored. This
# example uses an SQLite database; your application may have other needs
# (another database, an ORM like ActiveRecord, Redis, etc.)
#
# Feel to modify these functions to fit your needs or rewrite them entirely.


##
# Initializes the credentials store.
#
# @return [SQLite3::Database]
#   The SQLite3 database.
def init_credentials_store
  db = SQLite3::Database.new('credentials.sqlite3')
  test = "select count(*) from sqlite_master where name = 'credentials'"
  if db.get_first_value(test) == 0
    create = "create table credentials (userid text not null unique, " +
      "credentials text not null);"
    db.execute create
  end
  db
end

##
# Retrieved stored credentials for the provided user ID.
#
# @param [String] user_id
#   User's ID.
# @return [Signet::OAuth2::Client]
#   Stored OAuth 2.0 credentials if found, nil otherwise.
def get_stored_credentials(user_id)
  db = init_credentials_store
  row = db.get_first_row('select credentials from credentials " +
    "where userid = ?', user_id)
  if row
    hash = YAML::load(row[0])
    Signet::OAuth2::Client.new(hash)
  else
    nil
  end
end

##
# Gets an array containing the IDs of all users who have credentials in the
# database.
#
# @return [Array]
#   An array containing user IDs.
def list_stored_user_ids
  db = init_credentials_store
  db.execute('select userid from credentials')
end

##
# Store OAuth 2.0 credentials in the application's database.
#
# @param [String] user_id
#   User's ID.
# @param [Signet::OAuth2::Client] credentials
#   OAuth 2.0 credentials to store.
def store_credentials(user_id, credentials)
  hash = {
    access_token: credentials.access_token,
    refresh_token: credentials.refresh_token
  }
  db = init_credentials_store
  db.execute 'insert or replace into credentials values (?, ?)',
    user_id, hash.to_yaml
    
  get_stored_credentials(user_id)
end
