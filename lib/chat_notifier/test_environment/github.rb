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

      # "Re-run failed jobs" reuses GITHUB_RUN_ID (only GITHUB_RUN_ATTEMPT
      # changes), so the attempt suffix lets a re-run pass supersede the
      # original failure in the digest instead of being dropped as a
      # duplicate of the same run.
      def run_key
        attempt = settings.fetch("GITHUB_RUN_ATTEMPT", nil)
        return run_id unless run_id && attempt

        "#{run_id}.#{attempt}"
      end

      def pull_request_ref
        ref = settings.fetch("GITHUB_HEAD_REF", nil)
        ref unless ref.nil? || ref.empty?
      end
    end
  end
end
