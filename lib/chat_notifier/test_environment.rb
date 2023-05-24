# frozen_string_literal: true

module ChatNotifier
  # All information about the place where the test was run
  class TestEnvironment
    def initialize(settings:)
      @settings = settings
    end

    attr_reader :settings

    def self.for(settings)
      if settings["DEBUG"]
        Debug
      else
        Github
      end.new(settings: settings)
    end

    def ruby_version
      "Ruby #{::RUBY_VERSION}"
    end

    def url
      settings.fetch("NOTIFY_CURRENT_REPOSITORY_URL")
    end

    def test_run_url
    end
  end
end

require_relative "test_environment/github"
require_relative "test_environment/debug"
