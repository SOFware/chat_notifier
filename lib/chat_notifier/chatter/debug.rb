# frozen_string_literal: true

module ChatNotifier
  class Chatter
    class Debug < Slack
      Chatter.register self

      class << self
        def handles?(settings)
          !settings.keys.grep(/DEBUG/).empty?
        end
      end
    end
  end
end
