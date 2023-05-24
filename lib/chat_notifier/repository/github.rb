# frozen_string_literal: true

module ChatNotifier
  class Repository
    class Github < self
      def url
        settings.fetch("NOTIFY_CURRENT_REPOSITORY_URL", nil)
      end

      def link(sha)
        "#{url}/tree/#{sha}"
      end
    end
  end
end
