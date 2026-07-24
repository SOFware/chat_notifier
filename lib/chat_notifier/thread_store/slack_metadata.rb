# frozen_string_literal: true

module ChatNotifier
  class ThreadStore
    # Uses the Slack channel itself as the store: parents are posted with
    # message metadata carrying the thread key; find scans recent history.
    class SlackMetadata < self
      EVENT_TYPE = "chat_notifier_thread"
      HISTORY_URL = "https://slack.com/api/conversations.history"
      HISTORY_LIMIT = 200

      def initialize(chatter:)
        @chatter = chatter
      end

      attr_reader :chatter

      def find(key, process: nil)
        response = fetch_history(process)
        unless response["ok"]
          ChatNotifier.logger.error(
            "ChatNotifier: thread lookup failed: #{response.fetch("error", "unrecognized response")}"
          )
          return nil
        end
        message = matching_message(response, key)
        return nil unless message

        ThreadRef.new(ts: message["ts"], status: message.dig("metadata", "event_payload", "status"))
      rescue => error
        # A failed lookup must never abort posting the notification itself.
        ChatNotifier.logger.error("ChatNotifier: thread lookup failed: #{error.message}")
        nil
      end

      # Posting the parent with metadata is the record; nothing separate to do.
      def record(key, ref) = nil

      private

      # A nil process defers to the chatter's own default transport.
      def fetch_history(process)
        params = {
          channel: chatter.channel,
          limit: HISTORY_LIMIT,
          include_all_metadata: true
        }
        return chatter.api_form_post(HISTORY_URL, params) unless process

        chatter.api_form_post(HISTORY_URL, params, process:)
      end

      def matching_message(response, key)
        (response["messages"] || []).find do |message|
          message.dig("metadata", "event_type") == EVENT_TYPE &&
            message.dig("metadata", "event_payload", "key") == key
        end
      end
    end
  end
end
