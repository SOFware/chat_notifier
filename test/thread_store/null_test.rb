# frozen_string_literal: true

require "test_helper"
require "support/thread_store_contract"

describe ChatNotifier::ThreadStore::Null do
  let(:store) { ChatNotifier::ThreadStore::Null.new }
  let(:findable_key) { "app#main" }

  include ThreadStoreContract

  it "never finds a thread" do
    assert_nil store.find("app#main")
  end

  it "records without error" do
    ref = ChatNotifier::ThreadStore::ThreadRef.new(ts: "1.2", status: "failing")
    store.record("app#main", ref)
  end
end

describe ChatNotifier::ThreadStore::ThreadRef do
  it "is open unless resolved" do
    assert ChatNotifier::ThreadStore::ThreadRef.new(ts: "1", status: "failing").open?
    refute ChatNotifier::ThreadStore::ThreadRef.new(ts: "1", status: "resolved").open?
  end
end
