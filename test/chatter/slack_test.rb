# frozen_string_literal: true

require "test_helper"
require "json"
require "chat_notifier/chatter"

FakeResponse = Struct.new(:body)
MessengerDouble = Struct.new(:success?, :failure?, :lede, :message, :failures)
FailureLoc = Struct.new(:location)

describe ChatNotifier::Chatter::Slack do
  let(:settings) do
    {
      "NOTIFY_SLACK_WEBHOOK_URL" => "https://hooks.slack.com/abc/123",
      "NOTIFY_SLACK_NOTIFY_CHANNEL" => "#test"
    }
  end

  describe ".handles?" do
    describe "when settings contains keys with NOTIFY_SLACK" do
      it "returns true" do
        assert ChatNotifier::Chatter::Slack.handles?(settings), "Expected #{ChatNotifier::Chatter::Slack} to handle #{settings.inspect}"
      end
    end

    describe "when settings does not contain keys with NOTIFY_SLACK" do
      let(:settings) { {SLACK: "unrelated"} }

      it "returns false" do
        refute ChatNotifier::Chatter::Slack.handles?(settings), "Expected #{ChatNotifier::Chatter::Slack} not to handle #{settings.inspect}"
      end
    end
  end

  describe "#payload" do
    let(:communicator) { ChatNotifier::Chatter::Slack.new(settings:, repository: nil, environment: nil) }

    describe "when messenger indicates failure" do
      let(:messenger) { mimic(failure?: true, to_h: {}) }

      it "returns a hash containing a failure icon emoji" do
        expect(communicator.payload(messenger)).must_match(/:red_circle:/)
      end
    end

    describe "when messenger does not indicate failure" do
      let(:messenger) { mimic(failure?: false, to_h: {}) }

      it "returns a hash containing a success icon emoji" do
        expect(communicator.payload(messenger)).must_match(/:green_circle:/)
      end
    end
  end

  describe "#post with a bot token configured" do
    let(:settings) do
      {
        "NOTIFY_SLACK_BOT_TOKEN" => "xoxb-test-token",
        "NOTIFY_SLACK_NOTIFY_CHANNEL" => "#test",
        "NOTIFY_SLACK_THREAD_GROUP_SIZE" => 1
      }
    end
    let(:communicator) { ChatNotifier::Chatter::Slack.new(settings:, repository: nil, environment: nil) }

    let(:messenger) do
      MessengerDouble.new(
        success?: false,
        failure?: true,
        lede: ":boom: failed in branch main",
        message: "ignored",
        failures: [
          FailureLoc.new("test/a_test.rb:1"),
          FailureLoc.new("test/b_test.rb:2")
        ]
      )
    end

    def record_calls
      calls = []
      process = lambda do |uri, body, headers = nil|
        calls << {uri: uri.to_s, body: JSON.parse(body), headers: headers}
        FakeResponse.new(%({"ok":true,"ts":"111.222"}))
      end
      yield process
      calls
    end

    it "posts the parent message to the Web API with the bearer token" do
      calls = record_calls { |process| communicator.post(messenger, process:) }

      parent = calls.first
      expect(parent[:uri]).must_equal("https://slack.com/api/chat.postMessage")
      expect(parent[:headers]["Authorization"]).must_equal("Bearer xoxb-test-token")
      expect(parent[:body]["text"]).must_equal(":boom: failed in branch main")
      expect(parent[:body]["channel"]).must_equal("#test")
      refute parent[:body].key?("thread_ts"), "parent must not be a threaded reply"
    end

    it "posts each failure group as a threaded reply using the parent ts" do
      calls = record_calls { |process| communicator.post(messenger, process:) }

      replies = calls.drop(1)
      expect(replies.size).must_equal(2)
      replies.each do |reply|
        expect(reply[:body]["thread_ts"]).must_equal("111.222")
      end
      expect(replies[0][:body]["text"]).must_match(%r{test/a_test\.rb})
      expect(replies[1][:body]["text"]).must_match(%r{test/b_test\.rb})
    end

    it "prefers the bot token over a configured webhook" do
      settings["NOTIFY_SLACK_WEBHOOK_URL"] = "https://hooks.slack.com/abc/123"
      calls = record_calls { |process| communicator.post(messenger, process:) }

      expect(calls.first[:uri]).must_equal("https://slack.com/api/chat.postMessage")
    end

    it "does not post replies when the parent message fails" do
      calls = []
      process = lambda do |uri, body, headers = nil|
        calls << uri.to_s
        FakeResponse.new(%({"ok":false,"error":"channel_not_found"}))
      end

      communicator.post(messenger, process:)

      expect(calls.size).must_equal(1)
    end

    describe "when the run succeeds" do
      let(:messenger) do
        MessengerDouble.new(
          success?: true,
          failure?: false,
          lede: "ignored",
          message: ":thumbsup: all good",
          failures: []
        )
      end

      it "posts a single non-threaded message via the Web API" do
        calls = record_calls { |process| communicator.post(messenger, process:) }

        expect(calls.size).must_equal(1)
        expect(calls.first[:body]["text"]).must_equal(":thumbsup: all good")
        refute calls.first[:body].key?("thread_ts")
      end
    end
  end
end
