require "test_helper"
require "chat_notifier/test_environment"

describe ChatNotifier::TestEnvironment do
  let(:settings) do
    {
      "DEBUG" => debug,
      "NOTIFY_CURRENT_REPOSITORY_URL" => "https://github.com/test/test_repo"
    }
  end

  describe ".for" do
    subject { ChatNotifier::TestEnvironment.for(settings) }

    describe "when DEBUG is true" do
      let(:debug) { true }

      it "returns an instance of Debug" do
        test_env = ChatNotifier::TestEnvironment.for(settings)
        expect(test_env).must_be_instance_of(ChatNotifier::TestEnvironment::Debug)
      end
    end

    describe "when DEBUG is false" do
      let(:debug) { false }

      it "returns an instance of Github" do
        test_env = ChatNotifier::TestEnvironment.for(settings)
        expect(test_env).must_be_instance_of(ChatNotifier::TestEnvironment::Github)
      end
    end
  end
end
