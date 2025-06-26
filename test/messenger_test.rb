# frozen_string_literal: true

require "test_helper"
require "chat_notifier/messenger"

describe ChatNotifier::Messenger do
  # Simple test doubles
  AppDouble = Struct.new(:branch, :sha) do
    def to_s; "app"; end
  end

  RepositoryDouble = Struct.new(:url) do
    def link(branch)
      url
    end
  end
  EnvironmentDouble = Struct.new(:ruby_version, :test_run_url)
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

  describe "#message" do
    let(:summary) { SummaryDouble.new([]) }
    let(:environment) { EnvironmentDouble.new("Ruby 2.7.0")}
    let(:app) { AppDouble.new("test_branch", "abcdef123") }
    let(:repository) { RepositoryDouble.new("https://github.com/test/test_repo/test_branch") }

    it "returns a success message" do
      messenger = ChatNotifier::Messenger.for(summary, repository:, environment:, app:)
      expect(messenger.message).must_equal(":thumbsup: app Ruby 2.7.0 abcdef123 is OK on branch https://github.com/test/test_repo/test_branch")
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
