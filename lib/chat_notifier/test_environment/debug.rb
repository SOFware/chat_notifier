# frozen_string_literal: true

module ChatNotifier
  class TestEnvironment
    class Debug < self
      def url
        "http://example.com"
      end

      def test_run_url
        "#{url}/test-run/9999999"
      end
    end
  end
end
