# frozen_string_literal: true

require "test_helper"
require "json"
require "chat_notifier/chatter"

FakeResponse = Struct.new(:body)
RateLimitedResponse = Struct.new(:body, :code, :headers) do
  def [](key) = headers[key]
end
MessengerDouble = Struct.new(:success?, :failure?, :lede, :message, :failures, :thread_key, :status_report)
FailureLoc = Struct.new(:location)
StoreDouble = Struct.new(:ref) do
  def find(key, process: nil)
    finds << [key, process]
    ref
  end

  def finds
    @finds ||= []
  end
end

# MessengerDouble's Struct members are static values, but digest/resolved?
# take the reports argument — so this double records what it receives.
class DigestMessengerDouble
  def initialize(resolved: false)
    @resolved = resolved
  end

  attr_reader :digest_reports, :resolved_reports

  def success? = false

  def failure? = true

  def lede = ":boom: failed in branch main"

  def message = "ignored"

  def failures = [FailureLoc.new("test/a_test.rb:1")]

  def thread_key = "app#main"

  def status_report = {job: "test ruby-3.4", status: "failed", failures: 1, run_id: "42"}

  def digest(reports)
    @digest_reports = reports
    "DIGEST TEXT"
  end

  def resolved?(reports)
    @resolved_reports = reports
    @resolved
  end
end

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

    describe "when settings has NOTIFY_SLACK keys but no webhook or bot token" do
      let(:settings) { {"NOTIFY_SLACK_THREAD_GROUP_SIZE" => "5"} }

      it "returns false" do
        refute ChatNotifier::Chatter::Slack.handles?(settings), "Expected #{ChatNotifier::Chatter::Slack} not to handle settings with no credential"
      end
    end

    describe "when settings has only a bot token" do
      let(:settings) { {"NOTIFY_SLACK_BOT_TOKEN" => "xoxb-123"} }

      it "returns true" do
        assert ChatNotifier::Chatter::Slack.handles?(settings), "Expected #{ChatNotifier::Chatter::Slack} to handle bot-token settings"
      end
    end
  end

  describe "#thread_group_size" do
    let(:communicator) { ChatNotifier::Chatter::Slack.new(settings:, repository: nil, environment: nil) }

    describe "when the setting is not a number" do
      let(:settings) { {"NOTIFY_SLACK_THREAD_GROUP_SIZE" => "lots"} }

      it "falls back to the default" do
        expect(communicator.thread_group_size).must_equal(ChatNotifier::Chatter::Slack::DEFAULT_THREAD_GROUP_SIZE)
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

  describe "#thread_store" do
    it "defaults to the SlackMetadata store when a bot token is configured" do
      chatter = ChatNotifier::Chatter::Slack.new(
        settings: {"NOTIFY_SLACK_BOT_TOKEN" => "xoxb-123"}, repository: nil, environment: nil
      )
      expect(chatter.thread_store).must_be_instance_of(ChatNotifier::ThreadStore::SlackMetadata)
    end

    it "defaults to the null store when only a webhook is configured" do
      chatter = ChatNotifier::Chatter::Slack.new(settings:, repository: nil, environment: nil)
      expect(chatter.thread_store).must_be_instance_of(ChatNotifier::ThreadStore::Null)
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
        ],
        thread_key: "app#main",
        status_report: {job: "test ruby-3.4", status: "failed", failures: 2, run_id: "42"}
      )
    end

    before do
      # Pin a null store so these examples exercise posting behavior alone.
      # With the default SlackMetadata store the first recorded call would be
      # the conversations.history lookup rather than the parent message.
      communicator.thread_store = ChatNotifier::ThreadStore::Null.new
    end

    # Form-encoded bodies (conversations.replies) are recorded as raw strings.
    def record_calls
      calls = []
      process = lambda do |uri, body, headers = nil|
        parsed = begin
          JSON.parse(body)
        rescue JSON::ParserError
          body
        end
        calls << {uri: uri.to_s, body: parsed, headers: headers}
        FakeResponse.new(%({"ok":true,"ts":"111.222"}))
      end
      yield process
      calls
    end

    # chat.postMessage calls only — post_via_api now also fetches
    # conversations.replies after the status reply.
    def post_message_calls(calls)
      calls.select { |call| call[:uri] == "https://slack.com/api/chat.postMessage" }
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

      replies = post_message_calls(calls)[1..-2] # between the parent and the trailing status reply
      expect(replies.size).must_equal(2)
      replies.each do |reply|
        expect(reply[:body]["thread_ts"]).must_equal("111.222")
      end
      expect(replies[0][:body]["text"]).must_match(%r{test/a_test\.rb})
      expect(replies[1][:body]["text"]).must_match(%r{test/b_test\.rb})
    end

    it "posts a status reply with metadata after the failure replies" do
      calls = record_calls { |process| communicator.post(messenger, process:) }

      status = post_message_calls(calls).last[:body]
      expect(status["thread_ts"]).must_equal("111.222")
      expect(status["metadata"]["event_type"]).must_equal("chat_notifier_status")
      expect(status["metadata"]["event_payload"]["job"]).must_equal("test ruby-3.4")
      expect(status["metadata"]["event_payload"]["status"]).must_equal("failed")
    end

    it "posts parents with thread metadata carrying the key" do
      calls = record_calls { |process| communicator.post(messenger, process:) }

      metadata = calls.first[:body]["metadata"]
      expect(metadata["event_type"]).must_equal("chat_notifier_thread")
      expect(metadata["event_payload"]["key"]).must_equal("app#main")
      expect(metadata["event_payload"]["status"]).must_equal("failing")
    end

    it "threads into an existing open thread instead of posting a parent" do
      store = StoreDouble.new(ChatNotifier::ThreadStore::ThreadRef.new(ts: "7.7", status: "failing"))
      communicator.thread_store = store
      seen_process = nil
      calls = record_calls do |process|
        seen_process = process
        communicator.post(messenger, process:)
      end

      posts = post_message_calls(calls)
      refute posts.any? { |c| !c[:body].key?("thread_ts") }, "no new parent expected"
      expect(posts.first[:body]["thread_ts"]).must_equal("7.7")
      expect(store.finds).must_equal([["app#main", seen_process]])
    end

    it "starts a new thread when the existing thread is resolved" do
      store = StoreDouble.new(ChatNotifier::ThreadStore::ThreadRef.new(ts: "7.7", status: "resolved"))
      communicator.thread_store = store
      calls = record_calls { |process| communicator.post(messenger, process:) }

      refute calls.first[:body].key?("thread_ts"), "resolved thread must not be reused"
      metadata = calls.first[:body]["metadata"]
      expect(metadata["event_payload"]["key"]).must_equal("app#main")
      expect(metadata["event_payload"]["status"]).must_equal("failing")
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

    it "does not post replies when the parent response has no ts" do
      calls = []
      process = lambda do |uri, body, headers = nil|
        calls << uri.to_s
        FakeResponse.new(%({"ok":true}))
      end

      communicator.post(messenger, process:)

      expect(calls.size).must_equal(1)
    end

    it "logs the Slack error when the parent message fails" do
      process = ->(uri, body, headers = nil) { FakeResponse.new(%({"ok":false,"error":"channel_not_found"})) }

      logged = capture_logs { communicator.post(messenger, process:) }

      expect(logged).must_match(/channel_not_found/)
    end

    it "logs the Slack error when a threaded reply fails" do
      responses = [
        FakeResponse.new(%({"ok":true,"ts":"111.222"})),
        FakeResponse.new(%({"ok":false,"error":"ratelimited"}))
      ]
      process = ->(uri, body, headers = nil) { responses.shift || FakeResponse.new(%({"ok":true,"ts":"333.444"})) }

      logged = capture_logs { communicator.post(messenger, process:) }

      expect(logged).must_match(/ratelimited/)
    end

    it "retries once after the Retry-After delay when rate limited" do
      rate_limited = RateLimitedResponse.new(%({"ok":false,"error":"ratelimited"}), "429", {"Retry-After" => "7"})
      responses = [
        FakeResponse.new(%({"ok":true,"ts":"111.222"})),
        rate_limited,
        FakeResponse.new(%({"ok":true,"ts":"111.222"}))
      ]
      bodies = []
      process = lambda do |uri, body, headers = nil|
        bodies << begin
          JSON.parse(body)
        rescue JSON::ParserError
          body # form-encoded conversations.replies fetch
        end
        responses.shift || FakeResponse.new(%({"ok":true,"ts":"111.222"}))
      end
      slept = []
      communicator.sleeper = ->(seconds) { slept << seconds }

      communicator.post(messenger, process:)

      expect(slept).must_equal([7])
      # parent + first reply + its retry + second reply + status reply + replies fetch
      expect(bodies.size).must_equal(6)
      expect(bodies[1]["text"]).must_equal(bodies[2]["text"])
    end

    describe "recomputing the parent digest after the status reply" do
      let(:messenger) { DigestMessengerDouble.new }

      let(:replies_body) do
        JSON.generate({
          ok: true,
          messages: [
            {ts: "111.222", text: "parent"},
            {ts: "111.300", metadata: {event_type: "chat_notifier_status",
                                       event_payload: {job: "test ruby-3.2", status: "failed", failures: 3, run_id: "42"}}},
            {ts: "111.400", metadata: {event_type: "chat_notifier_status",
                                       event_payload: {job: "test ruby-3.3", status: "passed", failures: 0, run_id: "42"}}}
          ]
        })
      end

      def run_with_scripted_replies(messenger)
        responses = [
          FakeResponse.new(%({"ok":true,"ts":"111.222"})),
          FakeResponse.new(%({"ok":true,"ts":"111.300"})),
          FakeResponse.new(%({"ok":true,"ts":"111.400"})),
          FakeResponse.new(replies_body),
          FakeResponse.new(%({"ok":true}))
        ]
        calls = []
        process = lambda do |uri, body, headers = nil|
          calls << {uri: uri.to_s, body:, headers:}
          responses.shift || FakeResponse.new(%({"ok":true}))
        end
        communicator.post(messenger, process:)
        calls
      end

      it "fetches the thread's replies with metadata after posting the status reply" do
        calls = run_with_scripted_replies(messenger)

        fetch = calls[3]
        expect(fetch[:uri]).must_equal("https://slack.com/api/conversations.replies")
        expect(fetch[:body]).must_match(/ts=111\.222/)
        expect(fetch[:body]).must_match(/include_all_metadata/)
      end

      it "updates the parent with the digest of the status reports" do
        calls = run_with_scripted_replies(messenger)

        update = calls.last
        expect(update[:uri]).must_equal("https://slack.com/api/chat.update")
        body = JSON.parse(update[:body])
        expect(body["channel"]).must_equal("#test")
        expect(body["ts"]).must_equal("111.222")
        expect(body["text"]).must_equal("DIGEST TEXT")
        expect(body["metadata"]["event_type"]).must_equal("chat_notifier_thread")
        expect(body["metadata"]["event_payload"]["key"]).must_equal("app#main")
        expect(body["metadata"]["event_payload"]["status"]).must_equal("failing")
      end

      it "passes the parsed status payloads to the messenger digest" do
        run_with_scripted_replies(messenger)

        expect(messenger.digest_reports).must_equal([
          {"job" => "test ruby-3.2", "status" => "failed", "failures" => 3, "run_id" => "42"},
          {"job" => "test ruby-3.3", "status" => "passed", "failures" => 0, "run_id" => "42"}
        ])
      end

      it "marks the parent resolved when the messenger reports resolution" do
        messenger = DigestMessengerDouble.new(resolved: true)
        calls = run_with_scripted_replies(messenger)

        body = JSON.parse(calls.last[:body])
        expect(calls.last[:uri]).must_equal("https://slack.com/api/chat.update")
        expect(body["metadata"]["event_payload"]["status"]).must_equal("resolved")
      end
    end

    describe "#api_form_post" do
      it "form-encodes params with the bearer token and parses JSON" do
        captured = {}
        process = lambda do |uri, body, headers = nil|
          captured.merge!(uri: uri.to_s, body:, headers:)
          FakeResponse.new(%({"ok":true,"messages":[]}))
        end

        result = communicator.api_form_post("https://slack.com/api/conversations.history",
          {channel: "#test", limit: 200}, process:)

        expect(captured[:uri]).must_equal("https://slack.com/api/conversations.history")
        expect(captured[:body]).must_equal("channel=%23test&limit=200")
        expect(captured[:headers]["Content-Type"]).must_equal("application/x-www-form-urlencoded")
        expect(captured[:headers]["Authorization"]).must_equal("Bearer xoxb-test-token")
        expect(result).must_equal({"ok" => true, "messages" => []})
      end

      it "returns an empty hash on unparseable responses" do
        process = ->(uri, body, headers = nil) { FakeResponse.new("not json") }
        expect(communicator.api_form_post("https://slack.com/api/x", {}, process:)).must_equal({})
      end
    end

    describe "when the run succeeds" do
      let(:messenger) do
        MessengerDouble.new(
          success?: true,
          failure?: false,
          lede: "ignored",
          message: ":thumbsup: all good",
          failures: [],
          thread_key: "app#main"
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
