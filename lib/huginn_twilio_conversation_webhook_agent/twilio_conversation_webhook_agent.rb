module Agents
  class TwilioConversationWebhookAgent < Agent
    cannot_be_scheduled!
    cannot_receive_events!

    gem_dependency_check { defined?(Twilio) && defined?(Faraday) }

    description <<-MD
      The Twilio Conversation Webhook Agent sets up a webhook to receive conversation type events from Twilio and then emits certain messages as events

      #{'## Include 'twilio-ruby' and 'faraday' in your Gemfile to use this Agent!' if dependencies_missing?}

      In order to create events, configure Twilio to send converstaion post events to:
      ```
      #{post_url}
      ```
      #{'The placeholder symbols will be replaced by their values once the agent is saved.' unless id}

      Do *NOT* send the pre-message events to this webhook.  Twilio expects certain returns for those.

      Options:

      * `server_url` must be set to the URL of your Huginn installation (probably "https://#{ENV['DOMAIN']}"), which must be web-accessible.  Be sure to set http/https correctly.

      * `account_sid` and `auth_token` are your Twilio account credentials.

      * `chat_sid` is the service ID you are using for chat conversations.

      * `phone_book` is a hash of phone numbers with names to fill in when receiving messages. Optional.

      * 'expected_receive_period_in_days' is how often you expect to receive messages. Used to determin if agent is working.

    MD

    def default_options
      {
        'account_sid' => '{% credential twilio_account_sid %}',
        'auth_token' => '{% credential twilio_auth_token %}',
        'chat_sid' => 'ISXXXXXXXXXXXXXX',
        'server_url' => "https://#{ENV['DOMAIN'].presence || 'example.com'}",
        'phone_book' => {
          '+13025550012' => 'Example 1',
          '+13025550013' => 'Example 2'
        },
        'expected_receive_period_in_days' => 10
      }
    end

    def validate_options
      errors.add(:base, 'account_sid is required') unless options['account_sid'].present?
      errors.add(:base, 'auth_token is required') unless options['auth_token'].present?

      errors.add(:base, 'chat_sid is required') unless options['chat_sid'].present?

      errors.add(:base, 'expected_receive_period_in_days is required') unless options['expected_receive_period_in_days'].present?

      errors.add(:base, 'phone_book must be a hash if it exists') if options['phone_book'].present? && options['phone_book'] != Hash

    end

    def working?
      event_created_within?(interpolated['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def post_url
      if interpolated['server_url'].present?
        "#{interpolated['server_url']}/users/#{user.id}/web_requests/#{id || ':id'}/conversations"
      else
        "https://#{ENV['DOMAIN']}/users/#{user.id}/web_requests/#{id || ':id'}/conversastions"
      end
    end

    def receive_web_request(request)
      params = request.params.except(:action, :controller, :agent_id, :user_id, :format)
      method = request.method_symbol.to_s
      headers = request.headers

      secret = params.delete('secret')
      return ["Not Authorized", 401] unless secret == "conversations"

      signature = headers['HTTP_X_TWILIO_SIGNATURE']

      @validator ||= Twilio::Security::RequestValidator.new interpolated['auth_token']
      if !@validator.validate(post_url, params, signature)
        error("Twilio Signature Failed to Validate\n\n" +
             "URL: #{post_url}\n\n" +
             "POST params: #{params.inspect}\n\n" +
             "Signature: #{signature}"
             )
        return ["Not Authorized", 401]
      end
      
      #TODO: Do stuff here
      #
    end

    def phonebook_lookup(number)
      return number unless interpolated['phone_book'].present? and interpolated['phone_book'].is_a?(Hash)
      phone_book = interpolated['phone_book']

      return phone_book[number] if phone_book[number].present?
      number
    end

    def get_participants(conversation_sid)
      participants = twilio_client
        .conversations
        .conversations(conversation_sid)
        .participants
        .list

      bindings = participants.each_with_object([]) do |p, l|
        l <<= p.messaging_binding
      end

      numbers = bindings.each_with_object([]) do |p, l|
        l <<= p['address'] if p['address'].present?
        l <<= p['proxy_address'] if p['proxy_address'].present?
        l <<= p['projected_address'] if p['projected_address'].present?
      end
      numbers.uniq
    end

    def twilio_client
      @twilio_client ||= Twilio::REST::Client.new interpolated['account_sid'], interpolated['auth_token']
    end

    def media_get_link(media_sid)
      response = media_client.get("v1/Services/#{interpolated['chat_sid']}/Media/#{media_sid}")
      if response.status == 200
        data = JSON.parse response.body
        return data['links']['content_direct_temporary']
      end
      nil
    end
    
    def media_client
      @media_client ||= Faraday.new(url: 'https://mcs.us1.twilio.com') do |builder|
        builder.request :retry
        builder.request :basic_auth, interpolated['account_sid'], interpolated['auth_token']
        builder.adapter :net_http
      end
    end
  end
end
