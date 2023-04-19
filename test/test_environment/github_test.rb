# frozen_string_literal: true

require "test_helper"
require "chat_notifier/test_environment"

describe ChatNotifier::TestEnvironment::Github do
  let(:settings) do
    {
      "DEBUG" => false,
      "CURRENT_REPOSITORY_URL" => "https://github.com/test/test_repo",
      "TEST_RUN_ID" => "12345"
    }
  end

  describe "#test_run_url" do
    it "returns the URL for the test run on GitHub Actions" do
      expect(ChatNotifier::TestEnvironment::Github.new(settings: settings).test_run_url).must_equal("https://github.com/test/test_repo/actions/runs/12345")
    end
  end

  describe "#run_id" do
    it "returns the TEST_RUN_ID from settings" do
      expect(ChatNotifier::TestEnvironment::Github.new(settings: settings).run_id).must_equal("12345")
    end
  end
end
