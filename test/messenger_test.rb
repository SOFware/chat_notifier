# frozen_string_literal: true

require "test_helper"
require "chat_notifier/messenger"

describe ChatNotifier::Messenger do
  let(:failed_examples) { mimic(empty?: true) }
  let(:summary) { mimic(failed_examples: failed_examples, empty?: true) }
  let(:app) { mimic(branch: "test_branch", sha: "abcdef123", to_s: "app") }
  let(:repository) { mimic(link: "https://github.com/test/test_repo/test_branch") }
  let(:environment) { mimic(ruby_version: "Ruby 2.7.0", test_run_url: "https://github.com/test/test_repo/actions/runs/12345") }

  describe ".for" do
    describe "when there are no failed examples" do
      let(:summary) { mimic(failed_examples: []) }

      it "returns an instance of Messenger" do
        standin = mimic

        messenger = ChatNotifier::Messenger.for(summary, repository: standin, environment: standin, app: standin)
        expect(messenger).must_be_instance_of(ChatNotifier::Messenger)
        summary.verify
      end
    end

    describe "when there are failed examples" do
      let(:summary) { mimic(failed_examples: ["spec/test_spec.rb:10"]) }

      it "returns an instance of Messenger::Failure" do
        standin = mimic

        messenger = ChatNotifier::Messenger.for(summary, repository: standin, environment: standin, app: standin)
        expect(messenger).must_be_instance_of(ChatNotifier::Messenger::Failure)
        summary.verify
      end
    end
  end

  describe "#message" do
    let(:summary) { mimic(failed_examples: []) }
    let(:environment) { mimic(ruby_version: "Ruby 2.7.0")}
    let(:app) { mimic(sha: "abcdef123", branch: "test_branch", to_s: "app") }
    let(:repository) { mimic(link: ["https://github.com/test/test_repo/test_branch", "test_branch"]) }

    it "returns a success message" do
      messenger = ChatNotifier::Messenger.for(summary, repository:, environment:, app:)
      expect(messenger.message).must_equal(":thumbsup: app Ruby 2.7.0 abcdef123 is OK on branch https://github.com/test/test_repo/test_branch")
      summary.verify
    end
  end

  describe "Messenger::Failure" do
    let(:summary) { mimic(failed_examples: ["spec/test_spec.rb:10"]) }
    let(:app) { mimic(branch: "test_branch", sha: "abcdef123", to_s: "app") }
    let(:environment) { mimic(ruby_version: "Ruby 2.7.0", test_run_url: "https://github.com/test/test_repo/actions/runs/12345") }

    describe "#message" do
      it "returns a failure message" do
        messenger = ChatNotifier::Messenger.for(summary, repository: mimic, environment:, app:)
        location = mimic(location: "spec/test_spec.rb:10")

        summary.expect(:failed_examples, [location])
        summary.expect(:failed_examples, [location]) # hit twice by message expectation below

        expect(messenger.message).must_equal(<<~MESSAGE.chomp)
          :boom: app Ruby 2.7.0 abcdef123 has failed 1 times! in test_branch

          https://github.com/test/test_repo/actions/runs/12345

          spec/test_spec.rb:10
        MESSAGE
      end
    end
  end
end
