require "test_helper"
require "ostruct"
require "chat_notifier"

module ChatNotifier
  class Test < Minitest::Test
    def setup
      # Setup any necessary test data or mocks here
      @env = {} # Replace with actual environment data if needed
      @summary = "Test summary"
    end

    def test_app_returns_rails_app_name
      Object.const_set(
        :Rails,
        OpenStruct.new(
          application: OpenStruct.new(
            class: OpenStruct.new(
              module_parent: "TestApp"
            )
          )
        )
      )
      assert_equal "TestApp", ChatNotifier.app
    end

    def test_app_returns_env_name
      ENV["NOTIFY_APP_NAME"] = "TestApp"
      assert_equal "TestApp", ChatNotifier.app
    end

    def test_debug!
      mock_repository = Minitest::Mock.new
      mock_environment = Minitest::Mock.new
      mock_chatter = Minitest::Mock.new(ChatNotifier::Chatter::Debug)
      mock_messenger = Minitest::Mock.new

      Repository.stub(:for, mock_repository) do
        TestEnvironment.stub(:for, mock_environment) do
          Chatter.stub(:const_get, mock_chatter) do
            mock_chatter.expect(:new, mock_chatter, settings: @env, repository: mock_repository, environment: mock_environment)
            Messenger.stub(:for, mock_messenger) do
              mock_chatter.expect(:post, nil, [mock_messenger])

              ChatNotifier.debug!(@env, summary: @summary)

              mock_chatter.verify
            end
          end
        end
      end
    end

    def test_call
      original_app_name = ENV["NOTIFY_APP_NAME"]
      ENV["NOTIFY_APP_NAME"] = "TestApp"
      # Mock dependencies
      mock_repository = Minitest::Mock.new
      mock_environment = Minitest::Mock.new
      mock_messenger = Minitest::Mock.new
      mock_box = Minitest::Mock.new

      Repository.stub(:for, mock_repository) do
        TestEnvironment.stub(:for, mock_environment) do
          Chatter.stub(:handling, [mock_box]) do
            Messenger.stub(:for, mock_messenger) do
              mock_box.expect(:conditional_post, nil, [mock_messenger])

              ChatNotifier.call(summary: @summary)

              mock_box.verify
            end
          end
        end
      end
    ensure
      if original_app_name.nil?
        ENV.delete("NOTIFY_APP_NAME")
      else
        ENV["NOTIFY_APP_NAME"] = original_app_name
      end
    end
  end
end
