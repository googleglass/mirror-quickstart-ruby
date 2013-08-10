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


require './oauth_utils'

##
# A small facade that simplifies making some basic Mirror API calls.
#
# @author Tony Allevato
class MirrorClient
  ##
  # Creates a new Mirror client and uses the specified credentials to
  # authorize access.
  #
  # @param [#generate_authenticated_request] authorization
  #   The OAuth2 credentials used to authorize access.
  def initialize(authorization)
    @client = Google::APIClient.new(
      application_name: 'Mirror Quick Start: Ruby/Sinatra',
      application_version: '1.0')
    @client.authorization = authorization
    @mirror = @client.discovered_api('mirror', 'v1')
  end

  ##
  # Downloads data from the specified URL, using an authorized connection.
  #
  # @param [String] url
  #   The URL of the content to download.
  #
  # @return [Array]
  #   A byte array of the downloaded data.
  def download(url)
    @client.execute!(uri: url).body
  end

  ##
  # Retrieves (at most) the most recent "max_results" timeline cards that were
  # inserted by this Glassware. Paging is not supported by this call.
  #
  # @param [Fixnum] max_results
  #   The maximum number of timeline cards to retrieve.
  #
  # @return [Google::APIClient::Schema::Mirror::V1::TimelineListResponse]
  #   The response containing the list of Timeline cards.
  def list_timeline(max_results = nil)
    @client.execute!(
      api_method: @mirror.timeline.list,
      parameters: { maxResults: max_results }
    ).data
  end

  ##
  # Inserts a timeline card, with an optional attachment, into the user's
  # timeline.
  #
  # @param [Hash, Google::APIClient::Schema::Mirror::V1::TimelineItem] timeline_item
  #   The timeline card to insert, passed either as a hash describing its
  #   parameters or an actual TimelineItem object created elsewhere.
  # @param [String] attachment_path
  #   The file system path to the attachment, or nil to attach nothing.
  # @param [String] content_type
  #   The MIME type of the data being attached.
  #
  # @return [Google::APIClient::Schema::Mirror::V1::TimelineItem]
  #   The TimelineItem that was inserted.
  def insert_timeline_item(timeline_item, attachment_path = nil,
    content_type = nil)
    method = @mirror.timeline.insert

    # If a Hash was passed in, create an actual timeline item from it.
    if timeline_item.kind_of?(Hash)
      timeline_item = method.request_schema.new(timeline_item)
    end

    if attachment_path && content_type
      media = Google::APIClient::UploadIO.new(attachment_path, content_type)
      parameters = { 'uploadType' => 'multipart' }
    else
      media = nil
      parameters = nil
    end

    @client.execute!(
      api_method: method,
      body_object: timeline_item,
      media: media,
      parameters: parameters
    ).data
  end

  ##
  # Retrieves the TimelineItem with the specified identifier.
  #
  # @param [String] timeline_item_id
  #   The identifier of the timeline item to retrieve.
  # @return [Google::APIClient::Schema::Mirror::V1::TimelineItem]
  #   The TimelineItem that was retrieved.
  def get_timeline_item(timeline_item_id)
    @client.execute!(
      api_method: @mirror.timeline.get,
      parameters: { id: timeline_item_id }
    ).data
  end

  ##
  # Patches the timeline item with the specified identifier, replacing
  # any properties that are in timeline_item and leaving the rest
  # untouched.
  #
  # @param [String] timeline_item_id
  #   The identifier of the timeline item to patch.
  # @param [Hash, Google::APIClient::Schema::Mirror::V1::TimelineItem]
  #   A partially specified hash or TimelineItem containing the properties
  #   to be patched.
  def patch_timeline_item(timeline_item_id, timeline_item)
    method = @mirror.timeline.patch

    # If a Hash was passed in, create an actual timeline item from it.
    if timeline_item.kind_of?(Hash)
      timeline_item = method.request_schema.new(timeline_item)
    end

    @client.execute!(
      api_method: method,
      body_object: timeline_item,
      parameters: { id: timeline_item_id }
    ).data
  end

  ##
  # Deletes the timeline item with the specified identifier.
  #
  # @param [String] timeline_item_id
  #   The identifier of the timeline item to delete.
  def delete_timeline_item(timeline_item_id)
    @client.execute!(
      api_method: @mirror.timeline.delete,
      parameters: { id: timeline_item_id }
    )
  end

  ##
  # Lists the attachments associated with a timeline item.
  def list_timeline_attachments(timeline_item_id)
    @client.execute!(
      api_method: @mirror.timeline.attachments.list,
      parameters: { itemId: timeline_item_id }).data
  end

  ##
  # Gets the attachment associated with a timeline item.
  #
  # @param [String] timeline_item_id
  #   The identifier of the timeline item.
  # @param [String] attachment_id
  #   The identifier of the attachment.
  #
  # @return [Google::APIClient::Schema::Mirror::V1::Attachment]
  #   The Attachment that was retrieved.
  def get_timeline_attachment(timeline_item_id, attachment_id)
    @client.execute!(
      api_method: @mirror.timeline.attachments.get,
      parameters: {
        itemId: timeline_item_id,
        attachmentId: attachment_id
      }
    ).data
  end

  ##
  # Gets a contact. Raises Google::APIClient::ClientError if the contact
  # does not exist.
  #
  # @param [String] contact_id
  #   The identifier of the contact to retrieve.
  #
  # @return [Google::APIClient::Schema::Mirror::V1::Contact]
  #   The Contact that was retrieved.
  def get_contact(contact_id)
    @client.execute!(
      api_method: @mirror.contacts.get,
      parameters: { id: contact_id }
    ).data
  end

  ##
  # Inserts a new contact.
  #
  # @param [Hash | Google::APIClient::Schema::Mirror::V1::Contact] contact
  #   The contact to insert, passed either as a hash describing its parameters
  #   or an actual Contact object created elsewhere.
  #
  # @return [Google::APIClient::Schema::Mirror::V1::Contact]
  #   The Contact that was inserted.
  def insert_contact(contact)
    method = @mirror.contacts.insert

    if contact.kind_of?(Hash)
      contact = method.request_schema.new(contact)
    end

    @client.execute!(
      api_method: method,
      body_object: contact
    ).data
  end

  ##
  # Deletes a contact.
  #
  # @param [String] contact_id
  #   The identifier of the contact to delete.
  def delete_contact(contact_id)
    @client.execute!(
      api_method: @mirror.contacts.delete,
      parameters: { id: contact_id }
    )
  end

  ##
  # Gets the user's location.
  #
  # @param [String] location_id
  #   The identifier of the location to retrieve, or "latest" to get the
  #   user's most recent location.
  # @return [Google::APIClient::Schema::Mirror::V1::Location]
  #   The Location that was retrieved.
  def get_location(location_id)
    @client.execute!(
      api_method: @mirror.locations.get,
      parameters: { id: location_id }
    ).data
  end

  ##
  # Gets the list of current subscriptions.
  #
  # @return [Google::APIClient::Schema::Mirror::V1::SubscriptionListResponse]
  #   A SubscriptionListResponse object containing information about the
  #   current subscriptions.
  def list_subscriptions
    @client.execute!(api_method: @mirror.subscriptions.list).data
  end

  ##
  # Inserts a new subscription.
  #
  # @param [String] user_id
  #   The user token of the user to whom we want to subscribe.
  # @param [String] collection
  #   The collection ("timeline" or "location") to which we want to subscribe.
  # @param [String] callback_url
  #   The URL that will receive a POST request when a notification occurs.
  #
  # @return [Google::APIClient::Schema::Mirror::V1::Subscription]
  #   The Subscription that was created.
  def insert_subscription(user_id, collection, callback_url)
    subscription = @mirror.subscriptions.insert.request_schema.new({
      userToken: user_id,
      collection: collection,
      callbackUrl: callback_url
    })

    @client.execute!(
      api_method: @mirror.subscriptions.insert,
      body_object: subscription
    ).data
  end

  ##
  # Deletes a subscription.
  #
  # @param [String] id
  #   The identifier of the subscription to be deleted.
  def delete_subscription(id)
    @client.execute!(
      api_method: @mirror.subscriptions.delete,
      parameters: { id: id }
    )
  end
end
