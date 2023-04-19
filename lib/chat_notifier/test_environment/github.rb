# frozen_string_literal: true

module ChatNotifier
  class TestEnvironment
    class Github < self
      def test_run_url
        "#{url}/actions/runs/#{run_id}"
      end

      def run_id
        settings.fetch("TEST_RUN_ID")
      end
    end
  end
end
