require "test_helper"
require "chat_notifier"

module ChatNotifier
  class Test < Minitest::Test
    def setup
      # Setup any necessary test data or mocks here
      @env = {} # Replace with actual environment data if needed
      @summary = "Test summary"
    end

    def test_app_returns_rails_app_name
      # Save and remove any existing Rails constant
      original_rails = Object.const_get(:Rails) if Object.const_defined?(:Rails)
      Object.send(:remove_const, :Rails) if Object.const_defined?(:Rails)

      # Clear NOTIFY_APP_NAME to ensure Rails is used
      original_app_name = ENV["NOTIFY_APP_NAME"]
      ENV.delete("NOTIFY_APP_NAME")

      # Explicit class for application object
      app_class = Class.new do
        def self.module_parent
          "TestApp"
        end
      end
      app_object = app_class.new

      # Use Module.new and define_singleton_method to capture app_object
      rails_stub = Module.new
      rails_stub.define_singleton_method(:application) { app_object }
      Object.const_set(:Rails, rails_stub)

      assert_equal "TestApp", ChatNotifier.app(env: {}, name: nil)
    ensure
      # Restore original Rails constant if it existed
      if defined?(original_rails)
        Object.const_set(:Rails, original_rails)
      elsif Object.const_defined?(:Rails)
        Object.send(:remove_const, :Rails)
      end
      # Restore original app name
      if defined?(original_app_name)
        ENV["NOTIFY_APP_NAME"] = original_app_name
      end
    end

    def test_app_returns_env_name
      # Ensure Rails is not defined for this test
      if Object.const_defined?(:Rails)
        Object.send(:remove_const, :Rails)
      end

      ENV["NOTIFY_APP_NAME"] = "TestApp"
      assert_equal "TestApp", ChatNotifier.app
    end

    def test_debug!
      # Create simple test doubles
      test_repository = Object.new
      test_environment = Object.new
      test_chatter_class = Class.new do
        def initialize(settings:, repository:, environment:)
          @settings = settings
          @repository = repository
          @environment = environment
        end

        def post(messenger)
          # Test that post was called
        end
      end
      test_messenger = Object.new

      # Create test doubles for the factory methods using closures
      repository_factory = Class.new
      repository_factory.define_singleton_method(:for) { |env| test_repository }

      environment_factory = Class.new
      environment_factory.define_singleton_method(:for) { |env| test_environment }

      chatter_factory = Class.new
      chatter_factory.define_singleton_method(:const_get) { |notifier| test_chatter_class }

      messenger_factory = Class.new
      messenger_factory.define_singleton_method(:for) { |summary, app:, repository:, environment:| test_messenger }

      # Call debug! with dependency injection
      ChatNotifier.debug!(
        @env,
        summary: @summary,
        repository: repository_factory,
        environment: environment_factory,
        chatter: chatter_factory,
        messenger: messenger_factory
      )
    end

    def test_call
      original_app_name = ENV["NOTIFY_APP_NAME"]
      ENV["NOTIFY_APP_NAME"] = "TestApp"

      # Create simple test doubles
      test_repository = Object.new
      test_environment = Object.new
      test_messenger = Object.new
      test_box = Object.new

      def test_box.conditional_post(messenger)
        # Test that conditional_post was called
      end

      # Create test doubles for the factory methods using closures
      repository_factory = Class.new
      repository_factory.define_singleton_method(:for) { |env| test_repository }

      environment_factory = Class.new
      environment_factory.define_singleton_method(:for) { |env| test_environment }

      chatter_factory = Class.new
      chatter_factory.define_singleton_method(:handling) { |env, repository:, environment:| [test_box] }

      messenger_factory = Class.new
      messenger_factory.define_singleton_method(:for) { |summary, app:, repository:, environment:| test_messenger }

      # Call call with dependency injection
      ChatNotifier.call(
        summary: @summary,
        repository: repository_factory,
        environment: environment_factory,
        chatter: chatter_factory,
        messenger: messenger_factory
      )
    ensure
      if original_app_name.nil?
        ENV.delete("NOTIFY_APP_NAME")
      else
        ENV["NOTIFY_APP_NAME"] = original_app_name
      end
    end
  end
end
