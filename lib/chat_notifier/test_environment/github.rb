# frozen_string_literal: true

module ChatNotifier
  class TestEnvironment
    class Github < self
      def test_run_url
        "#{url}/actions/runs/#{run_id}"
      end

      def run_id
        settings.fetch("NOTIFY_TEST_RUN_ID") do
          settings.fetch("GITHUB_RUN_ID", nil)
        end
      end

      def pull_request_ref
        ref = settings.fetch("GITHUB_HEAD_REF", nil)
        ref unless ref.nil? || ref.empty?
      end
    end
  end
end
