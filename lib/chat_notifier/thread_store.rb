# frozen_string_literal: true

module ChatNotifier
  # Strategy for persisting the mapping from a branch/PR key to a chat thread.
  # Implementations provide find(key) => ThreadRef | nil and record(key, ref).
  class ThreadStore
    ThreadRef = Data.define(:ts, :status) do
      def open? = status != "resolved"
    end

    class Null < self
      def find(key) = nil

      def record(key, ref) = nil
    end
  end
end
