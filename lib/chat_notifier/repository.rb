# frozen_string_literal: true

module ChatNotifier
  # All information about the location of the source code
  class Repository
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

    def link(_sha)
    end
  end
end

require_relative "repository/github"
require_relative "repository/debug"
