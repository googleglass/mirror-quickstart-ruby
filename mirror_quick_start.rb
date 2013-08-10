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


require 'sinatra/base'
require './mirror_client'

##
# Contains the behavior of the Sinatra Quick Start application.
class MirrorQuickStart < Sinatra::Base

  set :haml, { format: :html5 }
  enable :sessions

  helpers do
    ##
    # Returns the base URL of the application.
    def base_url
      @base_url ||=
        "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end

    ##
    # Creates and returns a MirrorClient that is authorized by looking up
    # the stored credentials for the specified user ID.
    def make_client(user_id)
      @mirror = MirrorClient.new(get_stored_credentials(user_id))
    end

    ##
    # Bootstrap the new user by inserting a welcome item into their
    # timeline, creating the Ruby Quick Start contact, and subscribing
    # to timeline notifications.
    def bootstrap_new_user(mirror)
      mirror.insert_timeline_item({
        text: 'Welcome to the Mirror API Ruby Quick Start'
      })

      mirror.insert_contact({
        id: 'ruby-quick-start',
        displayName: 'Ruby Quick Start',
        imageUrls: ["#{base_url}/images/chipotle-tube-640x360.jpg"]
      })

      # Guard this statement in case the application is not running as HTTPS.
      begin
        callback = "#{base_url}/notify-callback"
        mirror.insert_subscription(session[:user_id], 'timeline', callback)
      rescue
        # Do nothing here.
      end
    end
  end
  
  ##
  # Called before any route (except for the authorization and notification
  # callbacks) is processed. Here we check to see if the user is currently
  # authenticated; if so, we create a Mirror client and store it for use in
  # the routes below. Otherwise, we redirect them to be authorized.
  before /^(?!\/(?:oauth2callback|notify-callback))/ do
    if session[:user_id].nil? || get_stored_credentials(session[:user_id]).nil?
      redirect to '/oauth2callback'
    else
      make_client(session[:user_id])
    end
  end

  ##
  # Handles the index route.
  get '/' do
    @message = session.delete(:message)

    @timeline = @mirror.list_timeline(3)

    begin
      @contact = @mirror.get_contact('ruby-quick-start')
    rescue Google::APIClient::ClientError => e
      @contact = nil
    end

    @timeline_subscription_exists = false
    @location_subscription_exists = false

    @mirror.list_subscriptions.items.each do |subscription|
      case subscription.id
      when 'timeline'
        @timeline_subscription_exists = true
      when 'locations'
        @location_subscription_exists = true
      end
    end

    haml :index
  end
  
  ##
  # Called when one of the buttons is clicked that inserts an item into
  # the timeline.
  post '/insert-item' do
    @mirror.insert_timeline_item(
      { text: params[:message] },
      "#{settings.public_folder}/#{params[:imageUrl]}",
      params[:contentType])

    session[:message] = 'Inserted a timeline item.'
    redirect to '/'
  end

  ##
  # Called when the button is clicked that inserts a new timeline item
  # that you can reply to.
  post '/insert-item-with-action' do
    @mirror.insert_timeline_item({
      text: 'What did you have for lunch?',
      speakableText: 'What did you eat? Bacon?',
      notification: { level: 'DEFAULT' },
      menuItems: [
        { action: 'REPLY' },
        { action: 'READ_ALOUD' },
        { action: 'SHARE' },
        { action: 'CUSTOM',
          id: 'safe-for-later',
          values: [{
            displayName: 'Drill Into',
            iconUrl: "#{base_url}/images/drill.png"
          }] }
      ]
    })

    session[:message] = 'Inserted a timeline item that you can reply to.'
    redirect to '/'
  end
  
  ##
  # Called when the button is clicked that inserts a Haml-rendered HTML
  # item into the user's timeline.
  post '/insert-pretty-item' do
    locals = {
      blue_line: params[:blue_line],
      green_line: params[:green_line],
      yellow_line: params[:yellow_line],
      red_line: params[:red_line]
    }

    # Make sure to specify layout: false or you'll end up rendering a
    # complete HTML document instead of just the partial.
    html = haml(:pretty, layout: false, locals: locals)
    @mirror.insert_timeline_item({ html: html })

    session[:message] = 'Inserted a pretty timeline item.'
    redirect to '/'
  end

  ##
  # Called when the button is clicked that inserts a timeline card into
  # all users' timelines.
  post '/insert-all-users' do
    user_ids = list_stored_user_ids
    if user_ids.length > 10
      session[:message] =
        "Found #{user_ids.length} users. Aborting to save your quota."
    else
      user_ids.each do |user_id|
        user_client = make_client(user_id)

        user_client.insert_timeline_item({
          text: "Did you know cats have 167 bones in their tails? Mee-wow!"
        })
      end

      session[:message] = "Sent a cat fact to #{user_ids.length} users."
    end

    redirect to '/'
  end

  ##
  # Called when the Delete button next to a timeline item is clicked.
  post '/delete-item' do
    @mirror.delete_timeline_item(params[:id])
    
    session[:message] = 'Deleted the timeline item.'
    redirect to '/'
  end

  ##
  # Called when the button is clicked that inserts a new contact.
  post '/insert-contact' do
    @mirror.insert_contact({
      id: 'ruby-quick-start',
      displayName: 'Ruby Quick Start',
      imageUrls: ["#{base_url}/images/chipotle-tube-640x360.jpg"]
    })

    session[:message] = 'Inserted the Ruby Quick Start contact.'
    redirect to '/'
  end

  ##
  # Called when the button is clicked that deletes the contact.
  post '/delete-contact' do
    @mirror.delete_contact('ruby-quick-start')

    session[:message] = 'Deleted the Ruby Quick Start contact.'
    redirect to '/'
  end

  ##
  # Called to insert a new subscription.
  post '/insert-subscription' do
    callback = "#{base_url}/notify-callback"

    begin
      @mirror.insert_subscription(
        session[:user_id], params[:subscriptionId], callback)

      session[:message] =
        "Subscribed to #{params[:subscriptionId]} notifications."
    rescue
      session[:message] =
        "Could not subscribe because the application is not running as HTTPS."
    end

    redirect to '/'
  end
  
  ##
  # Called to delete a subscription.
  post '/delete-subscription' do
    @mirror.delete_subscription(params[:subscriptionId])

    session[:message] =
      "Unsubscribed from #{params[:subscriptionId]} notifications."
    redirect to '/'
  end
  
  ##
  # Called to handle OAuth2 authorization.
  get '/oauth2callback' do
    if params[:code]
      # Handle step 2 of the OAuth 2.0 dance - code exchange
      credentials = get_credentials(params[:code], nil)
      user_info = get_user_info(credentials)
      session[:user_id] = user_info.id

      mirror = make_client(user_info.id)
      bootstrap_new_user(mirror)

      redirect to '/'
    elsif session[:user_id].nil? ||
        get_stored_credentials(session[:user_id]).nil?
      # Handle step 1 of the OAuth 2.0 dance - redirect to Google
      redirect to get_authorization_url(nil, nil)
    else
      # We're authenticated, so redirect back to the base URL.
      redirect to '/'
    end
  end
  
  ##
  # Called by the Mirror API to notify us of events that we are subscribed to.
  post '/notify-callback' do
    # The parameters for a subscription callback come as a JSON payload in
    # the body of the request, so we just overwrite the empty params hash
    # with those values instead.
    params = JSON.parse(request.body.read, symbolize_names: true)

    # The callback needs to create its own client with the user token from
    # the request.
    @client = make_client(params[:userToken])

    case params[:collection]
    when 'timeline'
      params[:userActions].each do |user_action|
        if user_action[:type] == 'SHARE'
          timeline_item_id = params[:itemId]

          timeline_item = @mirror.get_timeline_item(timeline_item_id)
          caption = timeline_item.text || ''

          # Alternatively, we could have updated the caption of the
          # timeline_item object itself and used the update method (especially
          # since we needed to get the full TimelineItem in order to retrieve
          # the original caption), but I wanted to illustrate the patch method
          # here.
          @mirror.patch_timeline_item(timeline_item_id,
            { text: "Ruby Quick Start got your photo! #{caption}" })
        end
      end
    when 'locations'
      location_id = params[:itemId]
      location = @mirror.get_location(location_id)

      # Insert a new timeline card with the user's location.
      @mirror.insert_timeline_item({
        text: "Ruby Quick Start says you are at " +
          "#{location.latitude} by #{location.longitude}." })
    else
      puts "I don't know how to process this notification: " +
        "#{params[:collection]}"
    end
  end

  ##
  # A proxy that lets us access the data for attachments (because it requires
  # authorization; we cannot just load the URL directly).
  get '/attachment-proxy' do
    attachment = @mirror.get_timeline_attachment(
      params[:timeline_item_id], params[:attachment_id])

    content_type attachment.content_type
    @mirror.download(attachment.content_url)
  end

  # Start the server if this Ruby script was started directly.
  run! if app_file == $0
end
