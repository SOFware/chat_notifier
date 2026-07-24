# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

require_relative "thread_store"

module ChatNotifier
  # All behavior for interacting with a notification platform
  class Chatter
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10

    def initialize(settings:, repository:, environment:)
      @settings = settings
      @repository = repository
      @environment = environment
    end

    attr_reader :settings, :repository, :environment

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

    def post(messenger, process: method(:http_post))
      uri = URI(webhook_url)

      process.call(uri, payload(messenger))
    end

    def conditional_post(messenger, process: method(:http_post))
      return if messenger.success? && !verbose?

      post(messenger, process:)
    end

    def http_client(uri)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
      end
    end

    def http_post(uri, body, headers = nil)
      http_client(uri).start do |http|
        http.request_post(uri.request_uri, body, headers)
      end
    end

    def verbose?
      !!settings.fetch("NOTIFIER_VERBOSE", false)
    end

    # Injectable store mapping thread keys to existing chat threads.
    attr_writer :thread_store

    def thread_store
      @thread_store ||= default_thread_store
    end

    def default_thread_store
      ThreadStore::Null.new
    end

    def payload(data)
      data.to_json
    end
  end
end

require_relative "chatter/slack"
require_relative "chatter/debug"
