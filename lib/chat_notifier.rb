# frozen_string_literal: true

require_relative "chat_notifier/version"

require_relative "chat_notifier/messenger"
require_relative "chat_notifier/repository"
require_relative "chat_notifier/test_environment"
require_relative "chat_notifier/chatter"

module ChatNotifier
  DebugExceptionLocation = Data.define(:location)
  DebugSummary = Data.define(:failed_examples)

  class << self
    # In order to test this locally see `rake chat_notifier:debug`
    def debug!(env, summary:, notifier: :Debug)
      repository = Repository.for(env)
      environment = TestEnvironment.for(env)

      chatter = Chatter.const_get(notifier).new(
        settings: env,
        repository: repository,
        environment: environment
      )
      messenger = Messenger.for(
        summary,
        app: Rails.application.class.module_parent,
        repository: repository,
        environment: environment
      )

      chatter.post(messenger)
    end

    def call(summary:)
      repository = Repository.for(ENV)
      environment = TestEnvironment.for(ENV)
      chatter = Chatter.handling(
        ENV,
        repository:,
        environment:
      )

      messenger = Messenger.for(
        summary,
        app: Rails.application.class.module_parent,
        repository:,
        environment:
      )

      chatter.each do |box|
        box.conditional_post(messenger)
      end
    end
  end
end
