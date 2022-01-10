# TwilioConversationWebhookAgent

## **NOTE** This agent is a work in progress and probably doesn't work right. 
For those currently looking for a way to get conversations working, I suggest the following:
- Use the   `Twilio Receive Text Agent` as the webhook for your incoming texts.
- Test for onMessageAdded to filter conversations with a Trigger Agent
```
{
  "expected_receive_period_in_days": "25",
  "keep_event": "true",
  "rules": [
    {
      "type": "field==value",
      "value": "onMessageAdded",
      "path": "EventType"
    }
  ],
  "message": "{{message}}"
}
```
- Use the [Twilio Get Participants Agent](https://github.com/paul-sx/huginn_twilio_get_participants_agent) to add a list of participants to your event
```
{
  "account_sid": "{% credential twilio_account_sid %}",
  "auth_token": "{% credential twilio_auth_token %}",
  "expected_receive_period_in_days": "30",
  "conversation_sid": "{{ ConversationSid }}"
}
```
- Trigger with the existance of the `Media` key to locate media
 ```
 {
  "expected_receive_period_in_days": "20",
  "keep_event": "true",
  "rules": [
    "{% assign returned =  false %}{% if Media%}{% assign returned = true %}{% endif %}{{returned}}"
  ]
}
```
- Use the [Twilio Get Media Urls Agent](https://github.com/paul-sx/huginn_twilio_get_media_urls_agent) to get a list of the media urls to download
```
{
  "account_sid": "{% credential twilio_account_sid %}",
  "auth_token": "{% credential twilio_auth_token %}",
  "chat_sid": "ISXXXXXXXXXXXXXX"
}
```
- Use the presence of the Body key to determine if there is text in the message
```
{
  "expected_receive_period_in_days": "20",
  "keep_event": "true",
  "rules": [
    "{% assign returned =  false %}{% if Body%}{% assign returned = true %}{% endif %}{{returned}}"
  ]
}
```


## Agent Summary
This agent is intended to serve as a replacement for the Standard `Twilio Receive Text Agent` agent for use with Twilio conversations.  The existing agent does function as a receiver for conversations, but lacks much of the necessary pieces to be fully useful.  In particular, the existing agent doesn't include the participants or any media files.  





## Installation

This gem is run as part of the [Huginn](https://github.com/huginn/huginn) project. If you haven't already, follow the [Getting Started](https://github.com/huginn/huginn#getting-started) instructions there.

Add this string to your Huginn's .env `ADDITIONAL_GEMS` configuration:

```ruby
huginn_twilio_conversation_webhook_agent(github: paul-sx/huginn_twilio_conversation_webhook_agent)
# when only using this agent gem it should look like this:
ADDITIONAL_GEMS=huginn_twilio_conversation_webhook_agent(github: paul-sx/huginn_twilio_conversation_webhook_agent)
```

And then execute:

    $ bundle

## Usage

TODO: Write usage instructions here

## Development

Running `rake` will clone and set up Huginn in `spec/huginn` to run the specs of the Gem in Huginn as if they would be build-in Agents. The desired Huginn repository and branch can be modified in the `Rakefile`:

```ruby
HuginnAgent.load_tasks(branch: '<your branch>', remote: 'https://github.com/<github user>/huginn.git')
```

Make sure to delete the `spec/huginn` directory and re-run `rake` after changing the `remote` to update the Huginn source code.

After the setup is done `rake spec` will only run the tests, without cloning the Huginn source again.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/paul-sx/huginn_twilio_conversation_webhook_agent/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
