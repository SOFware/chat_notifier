# frozen_string_literal: true

require "test_helper"
require "support/thread_store_contract"

FakeChatter = Struct.new(:channel, :responses) do
  def api_form_post(url, params, process: nil)
    calls << [url, params]
    (responses || []).shift || {}
  end

  def calls
    @calls ||= []
  end
end

describe ChatNotifier::ThreadStore::SlackMetadata do
  let(:history) do
    {"ok" => true, "messages" => [
      {"ts" => "9.9", "text" => "unrelated"},
      {"ts" => "5.5", "metadata" => {"event_type" => "chat_notifier_thread",
                                     "event_payload" => {"key" => "app#main", "status" => "failing"}}},
      {"ts" => "2.2", "metadata" => {"event_type" => "chat_notifier_thread",
                                     "event_payload" => {"key" => "app#main", "status" => "resolved"}}},
      {"ts" => "1.1", "metadata" => {"event_type" => "chat_notifier_thread",
                                     "event_payload" => {"key" => "app#other", "status" => "failing"}}}
    ]}
  end
  let(:chatter) { FakeChatter.new("#test", [history]) }
  let(:store) { ChatNotifier::ThreadStore::SlackMetadata.new(chatter:) }
  let(:findable_key) { "app#main" }

  include ThreadStoreContract

  it "finds the newest parent whose metadata matches the key" do
    ref = store.find("app#main")
    expect(ref.ts).must_equal("5.5")
    expect(ref.status).must_equal("failing")
  end

  it "requests channel history with metadata included" do
    store.find("app#main")
    url, params = chatter.calls.last
    expect(url).must_equal("https://slack.com/api/conversations.history")
    expect(params).must_equal({channel: "#test", limit: 200, include_all_metadata: true})
  end

  it "returns nil when no message matches" do
    assert_nil store.find("app#unknown")
  end

  it "returns nil and logs when the API errors" do
    chatter.responses = [{"ok" => false, "error" => "missing_scope"}]
    logged = capture_logs { assert_nil store.find("app#main") }
    expect(logged).must_match(/missing_scope/)
  end
end
