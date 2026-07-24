# frozen_string_literal: true

require "test_helper"
require "chat_notifier/messenger"

describe ChatNotifier::Messenger do
  # Simple test doubles
  AppDouble = Struct.new(:branch, :sha) do
    def to_s
      "app"
    end
  end

  RepositoryDouble = Struct.new(:url) do
    def link(branch)
      url
    end
  end
  EnvironmentDouble = Struct.new(:ruby_version, :test_run_url, :pull_request_ref, :job_identifier, :run_id)
  SummaryDouble = Struct.new(:failed_examples)
  LocationDouble = Struct.new(:location)

  let(:failed_examples) { [] }
  let(:summary) { SummaryDouble.new(failed_examples) }
  let(:app) { AppDouble.new("test_branch", "abcdef123") }
  let(:repository) { RepositoryDouble.new("https://github.com/test/test_repo/test_branch") }
  let(:environment) { EnvironmentDouble.new("Ruby 2.7.0", "https://github.com/test/test_repo/actions/runs/12345") }

  describe ".for" do
    describe "when there are no failed examples" do
      let(:summary) { SummaryDouble.new([]) }

      it "returns an instance of Messenger" do
        standin = Object.new
        messenger = ChatNotifier::Messenger.for(summary, repository: standin, environment: standin, app: standin)
        expect(messenger).must_be_instance_of(ChatNotifier::Messenger)
      end
    end

    describe "when there are failed examples" do
      let(:summary) { SummaryDouble.new(["spec/test_spec.rb:10"]) }

      it "returns an instance of Messenger::Failure" do
        standin = Object.new
        messenger = ChatNotifier::Messenger.for(summary, repository: standin, environment: standin, app: standin)
        expect(messenger).must_be_instance_of(ChatNotifier::Messenger::Failure)
      end
    end
  end

  describe "#thread_key" do
    it "combines app and branch when there is no pull request ref" do
      environment = EnvironmentDouble.new("Ruby 2.7.0", nil, nil)
      messenger = ChatNotifier::Messenger.new(summary:, app:, repository:, environment:)
      expect(messenger.thread_key).must_equal("app#test_branch")
    end

    it "combines app and pull request ref when present" do
      environment = EnvironmentDouble.new("Ruby 2.7.0", nil, "fix/thing")
      messenger = ChatNotifier::Messenger.new(summary:, app:, repository:, environment:)
      expect(messenger.thread_key).must_equal("app#fix/thing")
    end
  end

  describe "#message" do
    let(:summary) { SummaryDouble.new([]) }
    let(:environment) { EnvironmentDouble.new("Ruby 2.7.0") }
    let(:app) { AppDouble.new("test_branch", "abcdef123") }
    let(:repository) { RepositoryDouble.new("https://github.com/test/test_repo/test_branch") }

    it "returns a success message" do
      messenger = ChatNotifier::Messenger.for(summary, repository:, environment:, app:)
      expect(messenger.message).must_equal(":thumbsup: app Ruby 2.7.0 abcdef123 is OK on branch https://github.com/test/test_repo/test_branch")
    end
  end

  describe "#status_report" do
    let(:environment) { EnvironmentDouble.new("Ruby 2.7.0", nil, nil, "test ruby-3.4", "42") }

    describe "when the run passes" do
      let(:summary) { SummaryDouble.new([]) }

      it "reports a passed status with no failures" do
        messenger = ChatNotifier::Messenger.new(summary:, app:, repository:, environment:)
        expect(messenger.status_report).must_equal(
          {job: "test ruby-3.4", status: "passed", failures: 0, run_id: "42"}
        )
      end
    end

    describe "when the run fails" do
      let(:summary) { SummaryDouble.new([LocationDouble.new("spec/test_spec.rb:10")]) }

      it "reports a failed status with the failure count" do
        messenger = ChatNotifier::Messenger::Failure.new(summary:, app:, repository:, environment:)
        expect(messenger.status_report).must_equal(
          {job: "test ruby-3.4", status: "failed", failures: 1, run_id: "42"}
        )
      end
    end
  end

  describe "#digest" do
    let(:reports) do
      [
        {"job" => "test ruby-3.2", "status" => "failed", "failures" => 12, "run_id" => "43"},
        {"job" => "test ruby-3.3", "status" => "passed", "failures" => 0, "run_id" => "43"},
        {"job" => "test ruby-3.2", "status" => "failed", "failures" => 2, "run_id" => "42"}
      ]
    end
    let(:summary) { SummaryDouble.new([LocationDouble.new("spec/test_spec.rb:10")]) }
    let(:environment) { EnvironmentDouble.new("Ruby 2.7.0", "http://ci") }
    let(:messenger) { ChatNotifier::Messenger::Failure.new(summary:, app:, repository:, environment:) }

    it "renders latest-run job statuses and ignores older runs" do
      digest = messenger.digest(reports)
      expect(digest).must_match(/ruby-3\.2 ❌ 12/)
      expect(digest).must_match(/ruby-3\.3 ✅/)
      refute digest.match?(/❌ 2\b/), "older-run failure count must not appear"
    end

    it "converges: any ordering renders identical text" do
      texts = reports.permutation.map { |ordering| messenger.digest(ordering) }
      expect(texts.uniq.size).must_equal(1)
    end

    it "reports resolved when the latest run is all green" do
      all_green = [
        {"job" => "test ruby-3.2", "status" => "passed", "failures" => 0, "run_id" => "44"},
        {"job" => "test ruby-3.3", "status" => "failed", "failures" => 1, "run_id" => "43"}
      ]
      assert messenger.resolved?(all_green), "latest run all green must be resolved"
      refute messenger.resolved?(reports), "latest run with failures must not be resolved"
      expect(messenger.digest(all_green)).must_match(/\A✅/)
    end

    it "treats reports without run_id as the oldest run" do
      mixed = [
        {"job" => "legacy", "status" => "failed", "failures" => 5},
        {"job" => "test ruby-3.2", "status" => "passed", "failures" => 0, "run_id" => "43"}
      ]
      digest = messenger.digest(mixed)
      expect(digest).must_match(/ruby-3\.2 ✅/)
      refute digest.match?(/legacy/), "nil run_id reports must lose to a numbered run"
    end
  end

  describe "Messenger::Failure" do
    let(:summary) { SummaryDouble.new([LocationDouble.new("spec/test_spec.rb:10")]) }
    let(:app) { AppDouble.new("test_branch", "abcdef123") }
    let(:environment) { EnvironmentDouble.new("Ruby 2.7.0", "https://github.com/test/test_repo/actions/runs/12345") }

    describe "#message" do
      it "returns a failure message" do
        messenger = ChatNotifier::Messenger.for(summary, repository: Object.new, environment:, app:)
        expect(messenger.message).must_equal(<<~MESSAGE.chomp)
          :boom: app Ruby 2.7.0 abcdef123 has failed 1 times! in test_branch

          https://github.com/test/test_repo/actions/runs/12345

          spec/test_spec.rb:10
        MESSAGE
      end
    end
  end
end
