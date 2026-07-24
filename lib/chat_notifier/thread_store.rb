# frozen_string_literal: true

module ChatNotifier
  # Strategy for persisting the mapping from a branch/PR key to a chat thread.
  # Implementations provide find(key, process: nil) => ThreadRef | nil and
  # record(key, ref). The optional process is an injectable transport callable
  # passed through by callers; nil means use the implementation's default.
  class ThreadStore
    ThreadRef = Data.define(:ts, :status) do
      def open? = status != "resolved"
    end

    class Null < self
      def find(key, process: nil) = nil

      def record(key, ref) = nil
    end
  end
end

require_relative "thread_store/slack_metadata"
