require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::TwilioConversationWebhookAgent do
  before(:each) do
    @valid_options = Agents::TwilioConversationWebhookAgent.new.default_options
    @checker = Agents::TwilioConversationWebhookAgent.new(:name => "TwilioConversationWebhookAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
