# frozen_string_literal: true

require_relative "../failure_groups"

module ChatNotifier
  class Chatter
    class Slack < self
      Chatter.register self

      API_URL = "https://slack.com/api/chat.postMessage"
      DEFAULT_THREAD_GROUP_SIZE = 10

      class << self
        def handles?(settings)
          %w[NOTIFY_SLACK_WEBHOOK_URL NOTIFY_SLACK_BOT_TOKEN].any? do |key|
            settings.fetch(key, nil)
          end
        end
      end

      def webhook_url
        settings.fetch("NOTIFY_SLACK_WEBHOOK_URL", nil)
      end

      def bot_token
        settings.fetch("NOTIFY_SLACK_BOT_TOKEN", nil)
      end

      def channel
        settings.fetch("NOTIFY_SLACK_NOTIFY_CHANNEL", nil)
      end

      def thread_group_size
        Integer(settings.fetch("NOTIFY_SLACK_THREAD_GROUP_SIZE", DEFAULT_THREAD_GROUP_SIZE))
      rescue ArgumentError, TypeError
        DEFAULT_THREAD_GROUP_SIZE
      end

      # Injectable pause used when Slack rate-limits a post.
      attr_writer :sleeper

      def sleeper
        @sleeper ||= Kernel.method(:sleep)
      end

      # When a bot token is configured we use the Slack Web API, which can
      # thread failures. The token path is preferred over an incoming webhook.
      def post(messenger, process: method(:http_post))
        return super unless bot_token

        post_via_api(messenger, process:)
      end

      def payload(data)
        super(Configuration.for(data, self).to_h)
      end

      # Slack read APIs (conversations.history, conversations.replies) take
      # form-encoded params rather than JSON bodies.
      def api_form_post(url, params, process: method(:http_post))
        response = process.call(URI(url), URI.encode_www_form(params), form_headers)
        parsed_response(response)
      end

      # With a bot token the channel itself can store thread metadata.
      def default_thread_store
        return super unless bot_token

        ThreadStore::SlackMetadata.new(chatter: self)
      end

      private

      def post_via_api(messenger, process:)
        return post_message(text: messenger.message, process:) unless messenger.failure?

        key = messenger.thread_key
        ref = thread_store.find(key, process:)
        thread_ts = ref&.open? ? ref.ts : nil

        unless thread_ts
          parent = post_message(text: messenger.lede, process:, metadata: parent_metadata(key))
          return parent unless ok?(parent)
          thread_ts = response_ts(parent)
          return parent unless thread_ts
        end

        FailureGroups.new(messenger.failures, group_size: thread_group_size).reply_texts.each do |text|
          post_message(text:, thread_ts:, process:)
        end
      end

      def parent_metadata(key)
        {event_type: ThreadStore::SlackMetadata::EVENT_TYPE,
         event_payload: {key: key, status: "failing"}}
      end

      def post_message(text:, process:, thread_ts: nil, metadata: nil)
        body = {channel: channel, text: text}
        body[:thread_ts] = thread_ts if thread_ts
        body[:metadata] = metadata if metadata
        deliver = -> { process.call(URI(API_URL), body.to_json, api_headers) }

        response = deliver.call
        if rate_limited?(response)
          sleeper.call(retry_after(response))
          response = deliver.call
        end
        log_api_error(response)
        response
      end

      def rate_limited?(response)
        response.respond_to?(:code) && response.code.to_s == "429"
      end

      def retry_after(response)
        Integer(response["Retry-After"])
      rescue ArgumentError, TypeError
        1
      end

      def log_api_error(response)
        parsed = parsed_response(response)
        return if parsed["ok"] == true

        error = parsed.fetch("error", "unrecognized response")
        ChatNotifier.logger.error("ChatNotifier: Slack API error: #{error}")
      end

      def api_headers
        {
          "Content-Type" => "application/json; charset=utf-8",
          "Authorization" => "Bearer #{bot_token}"
        }
      end

      def form_headers
        {
          "Content-Type" => "application/x-www-form-urlencoded",
          "Authorization" => "Bearer #{bot_token}"
        }
      end

      def ok?(response)
        parsed_response(response)["ok"] == true
      end

      def response_ts(response)
        parsed_response(response)["ts"]
      end

      def parsed_response(response)
        JSON.parse(response.body.to_s)
      rescue JSON::ParserError
        {}
      end

      class Configuration
        def self.for(messenger, communicator)
          if messenger.failure?
            FailureConfiguration
          else
            self
          end.new(messenger, communicator).to_h
        end

        def initialize(messenger, communicator)
          @messenger = messenger
          @communicator = communicator
        end
        attr_reader :messenger, :communicator

        def icon_emoji = ":green_circle:"

        def to_h
          {
            channel: communicator.channel,
            icon_emoji: icon_emoji
          }.merge(messenger.to_h)
        end

        class FailureConfiguration < self
          def icon_emoji = ":red_circle:"
        end

        private_constant :FailureConfiguration
      end
      private_constant :Configuration
    end
  end
end
