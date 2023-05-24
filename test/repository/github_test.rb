# frozen_string_literal: true

require "test_helper"
require "chat_notifier/repository"

describe ChatNotifier::Repository::Github do
  let(:settings) do
    {
      "NOTIFY_CURRENT_REPOSITORY_URL" => "https://github.com/example/repo"
    }
  end
  let(:repository) { ChatNotifier::Repository::Github.new(settings: settings) }

  describe "#url" do
    it "returns the correct repository URL" do
      expect(repository.url).must_equal("https://github.com/example/repo")
    end
  end

  describe "#link" do
    let(:sha) { "abc123" }
    it "returns the correct link to the commit" do
      expect(repository.link(sha)).must_equal("https://github.com/example/repo/tree/abc123")
    end
  end
end
