# frozen_string_literal: true

module ChatNotifier
  class Repository
    class Debug < self
      def url
        "http://example.com"
      end

      def link(sha)
        "#{url}/tree/#{sha}"
      end
    end
  end
end
