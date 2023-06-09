# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module ChatNotifier
  # All behavior for interacting with a notification platform
  class Chatter
    def initialize(settings:, repository:, environment:)
      @settings = settings
      @repository = repository
      @environment = environment
    end

    attr :settings, :repository, :environment

    class << self
      def handlers
        @handlers ||= []
      end

      def handles?
        false
      end

      def register(klass)
        handlers << klass
      end

      def handling(settings, repository:, environment:)
        handlers.select { |handler| handler.handles?(settings) }.map do |klass|
          klass.new(
            settings: settings,
            repository: repository,
            environment: environment
          )
        end
      end
    end

    def webhook_url
    end

    def body
    end

    def post(messenger)
      uri = URI(webhook_url)

      Net::HTTP.post(uri, payload(messenger))
    end

    def conditional_post(messenger)
      return if messenger.success? && !verbose?

      post(messenger)
    end

    def verbose?
      !!settings.fetch("NOTIFIER_VERBOSE", false)
    end

    def payload(data)
      data.to_json
    end
  end
end

require_relative "chatter/slack"
require_relative "chatter/debug"
