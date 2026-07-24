# frozen_string_literal: true

require "test_helper"
require "chat_notifier/test_environment"

describe ChatNotifier::TestEnvironment::Github do
  let(:settings) do
    {
      "DEBUG" => false,
      "NOTIFY_CURRENT_REPOSITORY_URL" => "https://github.com/test/test_repo",
      "NOTIFY_TEST_RUN_ID" => "12345"
    }
  end

  describe "#test_run_url" do
    it "returns the URL for the test run on GitHub Actions" do
      expect(ChatNotifier::TestEnvironment::Github.new(settings: settings).test_run_url).must_equal("https://github.com/test/test_repo/actions/runs/12345")
    end
  end

  describe "#run_id" do
    it "returns the NOTIFY_TEST_RUN_ID from settings" do
      expect(ChatNotifier::TestEnvironment::Github.new(settings: settings).run_id).must_equal("12345")
    end

    it "prefers NOTIFY_TEST_RUN_ID and falls back to GITHUB_RUN_ID" do
      expect(ChatNotifier::TestEnvironment::Github.new(settings: {"NOTIFY_TEST_RUN_ID" => "77", "GITHUB_RUN_ID" => "88"}).run_id).must_equal("77")
      expect(ChatNotifier::TestEnvironment::Github.new(settings: {"GITHUB_RUN_ID" => "88"}).run_id).must_equal("88")
      assert_nil ChatNotifier::TestEnvironment::Github.new(settings: {}).run_id
    end
  end

  describe "#run_key" do
    it "appends the run attempt so re-runs of the same run sort later" do
      env = ChatNotifier::TestEnvironment::Github.new(
        settings: {"NOTIFY_TEST_RUN_ID" => "43", "GITHUB_RUN_ATTEMPT" => "2"}
      )
      expect(env.run_key).must_equal("43.2")
    end

    it "falls back to the bare run id without an attempt" do
      expect(ChatNotifier::TestEnvironment::Github.new(settings: {"NOTIFY_TEST_RUN_ID" => "43"}).run_key).must_equal("43")
      assert_nil ChatNotifier::TestEnvironment::Github.new(settings: {"GITHUB_RUN_ATTEMPT" => "2"}).run_key
    end

    it "does not change test_run_url which needs the bare run id" do
      env = ChatNotifier::TestEnvironment::Github.new(
        settings: settings.merge("GITHUB_RUN_ATTEMPT" => "2")
      )
      expect(env.test_run_url).must_equal("https://github.com/test/test_repo/actions/runs/12345")
    end
  end

  describe "#job_identifier" do
    it "combines the job name and ruby version" do
      env = ChatNotifier::TestEnvironment::Github.new(settings: {"GITHUB_JOB" => "test"})
      expect(env.job_identifier).must_equal("test ruby-#{RUBY_VERSION}")
    end

    it "prefers NOTIFY_JOB_NAME verbatim" do
      env = ChatNotifier::TestEnvironment::Github.new(settings: {"NOTIFY_JOB_NAME" => "custom"})
      expect(env.job_identifier).must_equal("custom")
    end
  end

  describe "#pull_request_ref" do
    it "returns GITHUB_HEAD_REF when present" do
      env = ChatNotifier::TestEnvironment::Github.new(settings: {"GITHUB_HEAD_REF" => "fix/thing"})
      expect(env.pull_request_ref).must_equal("fix/thing")
    end

    it "returns nil when GITHUB_HEAD_REF is empty or missing" do
      assert_nil ChatNotifier::TestEnvironment::Github.new(settings: {"GITHUB_HEAD_REF" => ""}).pull_request_ref
      assert_nil ChatNotifier::TestEnvironment::Github.new(settings: {}).pull_request_ref
    end
  end
end
