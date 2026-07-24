# frozen_string_literal: true

require "forwardable"

module ChatNotifier
  class Messenger
    extend Forwardable

    class << self
      def for(summary, repository:, environment:, app:)
        if summary.failed_examples.empty?
          self
        else
          Failure
        end.new(
          summary:,
          app:,
          repository:,
          environment:
        )
      end

      def debug=(val)
        prepend Debug if val
      end
    end

    module Debug
      def message = "This is only a test…"
    end

    def initialize(summary:, app:, repository:, environment:)
      @summary = summary
      @app = app
      @repository = repository
      @environment = environment
    end

    attr_reader :summary, :app, :repository, :environment

    def failures = summary.failed_examples

    def_delegator :failures, :count
    def_delegators :app, :branch, :sha
    def_delegator :environment, :ruby_version

    def message
      "#{message_prefix} #{identifier} is OK on branch #{repository.link(branch)}"
    end

    def lede = message

    def body = ""

    def identifier
      "#{app} #{ruby_version} #{sha}"
    end

    def thread_key
      "#{app}##{environment.pull_request_ref || branch}"
    end

    def message_prefix = ":thumbsup:"

    def status_report
      {job: environment.job_identifier, status: "passed", failures: 0, run_id: environment.run_id}
    end

    def success? = true

    def failure? = !success?

    # Render a parent-message summary from the thread's status reports,
    # keeping only the latest run's report per job. Deterministic for any
    # ordering of the same reports so repeated recomputes converge.
    def digest(reports)
      latest = latest_run(reports)
      parts = latest.sort_by { |report| report["job"].to_s }.map do |report|
        if report["status"] == "passed"
          "#{report["job"]} ✅"
        else
          "#{report["job"]} ❌ #{report["failures"]}"
        end
      end
      prefix = resolved?(reports) ? "✅" : message_prefix
      "#{prefix} #{identifier} in #{branch} · #{parts.join(" · ")}\n#{environment.test_run_url}"
    end

    def resolved?(reports)
      latest = latest_run(reports)
      !latest.empty? && latest.all? { |report| report["status"] == "passed" }
    end

    def to_h
      {
        text: message
      }
    end

    def to_hash = to_h

    class Failure < self
      def count = "#{failures.size} times!"

      def message_prefix = ":boom:"

      def success? = false

      def failure? = !success?

      def status_report
        super.merge(status: "failed", failures: failures.size)
      end

      def lede
        <<~LEDE.chomp
          #{message_prefix} #{identifier} has failed #{count} in #{branch}

          #{environment.test_run_url}
        LEDE
      end

      def message
        <<~MESSAGE.chomp
          #{lede}

          #{body}
        MESSAGE
      end

      def body
        failures.flat_map(&:location).join("\n")
      end
    end

    private

    def latest_run(reports)
      grouped = reports.group_by { |report| report["run_id"].to_s }
      latest_id = grouped.keys.max_by { |id| [id.length, id] }
      # [length, value] orders numeric strings correctly ("9" < "10") and
      # sorts nil run_ids ("") as the oldest run.
      # conversations.replies returns replies oldest-first, so uniq keeps the
      # earliest status per job per run; jobs post once per run, so it's fine.
      grouped.fetch(latest_id, []).uniq { |report| report["job"] }
    end
  end
end
