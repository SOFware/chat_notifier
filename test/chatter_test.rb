# frozen_string_literal: true

require "test_helper"
require "chat_notifier/chatter"

describe ChatNotifier::Chatter do
  let(:repository) { Object.new }
  let(:environment) { Object.new }

  describe "#http_client" do
    let(:chatter) { ChatNotifier::Chatter.new(settings: {}, repository:, environment:) }

    it "configures short timeouts so notifications cannot hang the test run" do
      client = chatter.http_client(URI("https://slack.com/api/chat.postMessage"))

      expect(client.open_timeout).must_equal(ChatNotifier::Chatter::OPEN_TIMEOUT)
      expect(client.read_timeout).must_equal(ChatNotifier::Chatter::READ_TIMEOUT)
    end

    it "uses SSL for https URIs" do
      client = chatter.http_client(URI("https://slack.com/api/chat.postMessage"))

      assert client.use_ssl?, "expected SSL to be enabled for https"
    end
  end

  describe "#verbose?" do
    describe "when NOTIFIER_VERBOSE is not set" do
      it "returns false" do
        refute ChatNotifier::Chatter.new(
          settings: {},
          repository:,
          environment:
        ).verbose?, "verbose? should be false"
      end
    end

    describe "when NOTIFIER_VERBOSE is set" do
      it "returns true" do
        assert ChatNotifier::Chatter.new(
          settings: {"NOTIFIER_VERBOSE" => "true"},
          repository:,
          environment:
        ).verbose?, "verbose? should be true"
      end
    end
  end
end
