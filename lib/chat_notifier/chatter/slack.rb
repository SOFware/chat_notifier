# frozen_string_literal: true

module ChatNotifier
  class Chatter
    class Slack < self
      Chatter.register self

      class << self
        def handles?(settings)
          !settings.keys.grep(/SLACK/).empty?
        end
      end

      def webhook_url
        settings.fetch("NOTIFY_SLACK_WEBHOOK_URL", nil)
      end

      def channel
        settings.fetch("NOTIFY_SLACK_NOTIFY_CHANNEL", nil)
      end

      def payload(data)
        super(Configuration.for(data, self).to_h)
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
