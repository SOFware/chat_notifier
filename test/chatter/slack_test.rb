# frozen_string_literal: true

require "test_helper"
require "chat_notifier/chatter"

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
      let(:settings) { { SLACK: "unrelated" } }

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
end
