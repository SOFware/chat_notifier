# frozen_string_literal: true

require "test_helper"
require "chat_notifier/app"

describe ChatNotifier::App do
  describe "#to_s" do
    it "returns the name" do
      app = ChatNotifier::App.new(name: "MyApp", settings: {})
      expect(app.to_s).must_equal("MyApp")
    end
  end

  describe "#branch" do
    it "prefers NOTIFY_BRANCH over CI-provided refs" do
      app = ChatNotifier::App.new(name: "MyApp", settings: {
        "NOTIFY_BRANCH" => "custom-branch",
        "GITHUB_HEAD_REF" => "pr-head",
        "GITHUB_REF_NAME" => "ref-name"
      })
      expect(app.branch).must_equal("custom-branch")
    end

    it "falls back to GITHUB_HEAD_REF, skipping empty settings" do
      app = ChatNotifier::App.new(name: "MyApp", settings: {
        "NOTIFY_BRANCH" => "",
        "GITHUB_HEAD_REF" => "pr-head",
        "GITHUB_REF_NAME" => "ref-name"
      })
      expect(app.branch).must_equal("pr-head")
    end

    it "falls back to GITHUB_REF_NAME when GITHUB_HEAD_REF is empty" do
      app = ChatNotifier::App.new(name: "MyApp", settings: {
        "GITHUB_HEAD_REF" => "",
        "GITHUB_REF_NAME" => "main"
      })
      expect(app.branch).must_equal("main")
    end

    it "falls back to the current git branch when settings provide nothing" do
      app = ChatNotifier::App.new(name: "MyApp", settings: {})
      expect(app.branch).must_be_instance_of(String)
      refute app.branch.empty?, "expected the git branch fallback to produce a value"
    end
  end

  describe "#sha" do
    it "prefers NOTIFY_SHA over GITHUB_SHA" do
      app = ChatNotifier::App.new(name: "MyApp", settings: {
        "NOTIFY_SHA" => "abc1234",
        "GITHUB_SHA" => "def5678"
      })
      expect(app.sha).must_equal("abc1234")
    end

    it "falls back to GITHUB_SHA, skipping empty settings" do
      app = ChatNotifier::App.new(name: "MyApp", settings: {
        "NOTIFY_SHA" => "",
        "GITHUB_SHA" => "def5678"
      })
      expect(app.sha).must_equal("def5678")
    end

    it "falls back to the current git sha when settings provide nothing" do
      app = ChatNotifier::App.new(name: "MyApp", settings: {})
      expect(app.sha).must_be_instance_of(String)
      refute app.sha.empty?, "expected the git sha fallback to produce a value"
    end
  end

  describe "used by a Messenger built through the real factories" do
    # Regression test: passing a bare String as app: made lede/message/
    # thread_key raise NoMethodError (undefined method 'branch' for String),
    # silently dropping every production notification.
    let(:settings) do
      {
        "NOTIFY_APP_NAME" => "MyApp",
        "NOTIFY_CURRENT_REPOSITORY_URL" => "https://github.com/test/repo",
        "NOTIFY_TEST_RUN_ID" => "1",
        "NOTIFY_BRANCH" => "feature-branch",
        "NOTIFY_SHA" => "abc1234"
      }
    end

    let(:messenger) do
      ChatNotifier::Messenger.for(
        ChatNotifier::DebugSummary.new(failed_examples: []),
        repository: ChatNotifier::Repository.for(settings),
        environment: ChatNotifier::TestEnvironment.for(settings),
        app: ChatNotifier::App.new(name: ChatNotifier.app(env: settings), settings: settings)
      )
    end

    it "resolves thread_key with the branch" do
      expect(messenger.thread_key).must_equal("MyApp#feature-branch")
    end

    it "resolves lede with the sha and branch" do
      expect(messenger.lede).must_include("abc1234")
      expect(messenger.lede).must_include("feature-branch")
    end

    it "resolves message with the sha and branch" do
      expect(messenger.message).must_include("abc1234")
      expect(messenger.message).must_include("feature-branch")
    end
  end
end
