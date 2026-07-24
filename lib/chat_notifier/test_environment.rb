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

    def job_identifier
      settings.fetch("NOTIFY_JOB_NAME") do
        job = settings.fetch("GITHUB_JOB", "test")
        "#{job} ruby-#{RUBY_VERSION}"
      end
    end

    def run_id
    end

    # Key used to group status reports by run in the parent digest. Distinct
    # from run_id (which URLs need bare) so re-runs can sort as newer runs.
    def run_key = run_id

    def pull_request_ref
    end
  end
end

require_relative "test_environment/github"
require_relative "test_environment/debug"
