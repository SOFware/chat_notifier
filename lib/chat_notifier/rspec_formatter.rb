# frozen_string_literal: true

require "rspec/core/formatters"
RSpec::Support.require_rspec_core "formatters/base_formatter"

require "chat_notifier"

module ChatNotifier
  # Formatter for RSpec tests to receive the summary of a test
  # run after the suite has finished.
  class RspecFormatter < RSpec::Core::Formatters::BaseFormatter
    RSpec::Core::Formatters.register self, :dump_summary

    def dump_summary(summary)
      ChatNotifier.call(summary:)
    end
  end
end
