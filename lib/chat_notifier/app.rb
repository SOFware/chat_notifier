# frozen_string_literal: true

module ChatNotifier
  # The application under test: its name plus the source control context
  # (branch and sha), resolved from CI-standard settings with git fallbacks.
  class App
    def initialize(name:, settings:)
      @name = name
      @settings = settings
    end

    attr_reader :name, :settings

    def to_s = name

    def branch
      return @branch if defined?(@branch)

      @branch = from_settings("NOTIFY_BRANCH", "GITHUB_HEAD_REF", "GITHUB_REF_NAME") ||
        git("branch --show-current")
    end

    def sha
      return @sha if defined?(@sha)

      @sha = from_settings("NOTIFY_SHA", "GITHUB_SHA") ||
        git("rev-parse --short HEAD")
    end

    private

    def from_settings(*keys)
      keys.each do |key|
        value = settings[key]
        return value unless value.nil? || value.empty?
      end
      nil
    end

    def git(command)
      value = `git #{command} 2>/dev/null`.chomp
      value.empty? ? nil : value
    rescue
      nil
    end
  end
end
