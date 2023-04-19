# frozen_string_literal: true

require "forwardable"

module ChatNotifier
  class Messenger
    extend Forwardable

    class << self
      def for(summary, repository:, environment:, app:)
        if summary.failed_examples.empty?
          self
        else
          Failure
        end.new(
          summary:,
          app:,
          repository:,
          environment:
        )
      end

      def debug=(val)
        prepend Debug if val
      end
    end

    module Debug
      def message = "This is only a test…"
    end

    def initialize(summary:, app:, repository:, environment:)
      @summary = summary
      @app = app
      @repository = repository
      @environment = environment
    end

    attr :summary, :app, :repository, :environment

    def failures = summary.failed_examples

    def_delegator :failures, :count
    def_delegators :app, :branch, :sha
    def_delegator :environment, :ruby_version

    def message
      "#{message_prefix} #{identifier} is OK on branch #{repository.link(branch)}"
    end

    def lede = message

    def body = ""

    def identifier
      "#{app} #{ruby_version} #{sha}"
    end

    def message_prefix = ":thumbsup:"

    def success? = true

    def failure? = !success?

    def to_h
      {
        text: message
      }
    end

    def to_hash = to_h

    class Failure < self
      def count = "#{failures.size} times!"

      def message_prefix = ":boom:"

      def success? = false

      def failure? = !success?

      def lede
        <<~LEDE.chomp
          #{message_prefix} #{identifier} has failed #{count} in #{branch}

          #{environment.test_run_url}
        LEDE
      end

      def message
        <<~MESSAGE.chomp
          #{lede}

          #{body}
        MESSAGE
      end

      def body
        failures.flat_map(&:location).join("\n")
      end
    end
  end
end
