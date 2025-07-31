# frozen_string_literal: true

require_relative "chat_notifier/version"

require_relative "chat_notifier/messenger"
require_relative "chat_notifier/repository"
require_relative "chat_notifier/test_environment"
require_relative "chat_notifier/chatter"

module ChatNotifier
  DebugExceptionLocation = Data.define(:location)
  DebugSummary = Data.define(:failed_examples)

  require "logger"
  @logger = Logger.new($stdout)
  class << self
    attr_accessor :logger

    def app(env: ENV, name: env.fetch("NOTIFY_APP_NAME"))
      name ||= if defined?(::Rails) && Rails.respond_to?(:application)
        Rails.application.class.module_parent
      else
        raise "No app name provided and Rails is not defined"
      end
    end

    STANDARDS = {
      repository: Repository,
      environment: TestEnvironment,
      chatter: Chatter,
      messenger: Messenger
    }

    # In order to test this locally see `rake chat_notifier:debug`
    def debug!(env, summary:, notifier: :Debug, **kwargs)
      repository = (kwargs[:repository] || STANDARDS[:repository]).for(env)
      environment = (kwargs[:environment] || STANDARDS[:environment]).for(env)

      chatter = (kwargs[:chatter] || STANDARDS[:chatter]).const_get(notifier).new(
        settings: env,
        repository: repository,
        environment: environment
      )
      messenger = (kwargs[:messenger] || STANDARDS[:messenger]).for(
        summary,
        app:,
        repository:,
        environment:
      )

      chatter.post(messenger)
    end

    def call(summary:, **kwargs)
      repository = (kwargs[:repository] || STANDARDS[:repository]).for(ENV)
      environment = (kwargs[:environment] || STANDARDS[:environment]).for(ENV)
      chatter = (kwargs[:chatter] || STANDARDS[:chatter]).handling(
        ENV,
        repository:,
        environment:
      )

      messenger = (kwargs[:messenger] || STANDARDS[:messenger]).for(
        summary,
        app:,
        repository:,
        environment:
      )

      chatter.each do |box|
        box.conditional_post(messenger)
      rescue => exception
        logger.error("ChatNotifier: #{box.webhook_url} #{exception.class}: #{exception.message}")
      end
    end
  end
end
