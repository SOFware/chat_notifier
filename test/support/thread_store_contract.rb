# frozen_string_literal: true

# Shared contract every ThreadStore implementation must satisfy.
# Including specs must define `store` (a let) and `findable_key`
# (a key the store may or may not resolve).
module ThreadStoreContract
  def self.included(base)
    base.class_eval do
      it "responds to find and record" do
        assert_respond_to store, :find
        assert_respond_to store, :record
      end

      it "find returns nil or a ThreadRef" do
        result = store.find(findable_key)
        assert result.nil? || result.is_a?(ChatNotifier::ThreadStore::ThreadRef),
          "find must return nil or ThreadRef, got #{result.inspect}"
      end

      it "find accepts an injectable process keyword" do
        assert_includes store.method(:find).parameters, [:key, :process],
          "find must accept a process: keyword so callers can inject transport"
      end
    end
  end
end
