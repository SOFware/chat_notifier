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
