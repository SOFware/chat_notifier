# ChatNotifier

Notify a chat room with data from your test run.

## Installation

```ruby
gem "chat_notifier", git: "https://github.com/SOFware/chat_notifier.git"
```

## Usage

### Minitest

Your minitest suite should pick up the formatter automatically.

### RSpec

Add to your `spec_helper.rb` or `rails_helper.rb`:

```ruby
require "chat_notifier/rspec_formatter"

config.add_formatter "ChatNotifier::RspecFormatter" if ENV["CI"]
```

Add to your config/application.rb within your namespaced module

```ruby
  def self.sha
    `git rev-parse --short HEAD`.chomp
  end

  def self.branch
    `git branch --show-current`.chomp
  end
```

Add these variables to your env files

```
      NOTIFY_SLACK_WEBHOOK_URL
      NOTIFY_SLACK_NOTIFY_CHANNEL
      NOTIFY_CURRENT_REPOSITORY_URL
      NOTIFY_TEST_RUN_ID
```

If you are _not_ using Rails, you will need to add this ENV variable:

```
      NOTIFY_APP_NAME
```

### Threaded failure notifications (optional)

Incoming webhooks post a single message. If you instead provide a Slack **bot
token**, ChatNotifier uses the Slack Web API and threads failures: it posts the
branch/run summary as a parent message, then posts the failing files — grouped
into reasonably sized batches — as threaded replies.

```
      NOTIFY_SLACK_BOT_TOKEN        # xoxb-… bot token; enables threading
      NOTIFY_SLACK_NOTIFY_CHANNEL   # channel id or name to post to
      NOTIFY_SLACK_THREAD_GROUP_SIZE # optional, files per reply (default 10)
```

When both `NOTIFY_SLACK_BOT_TOKEN` and `NOTIFY_SLACK_WEBHOOK_URL` are set, the
bot token is preferred. The bot needs the `chat:write` scope.

### Debug your Slack setup

Create rake task to test the connection to your Slack channel

```ruby
namespace :chat_notifier do
  desc "Tests chat notifier"
  task debug: :environment do
    unless ENV["NOTIFY_SLACK_WEBHOOK_URL"]
      puts "You MUST set the environment variables for:\nNOTIFY_SLACK_WEBHOOK_URL"
      return
    end
    ENV["DEBUG"] = "1"
    ENV["NOTIFY_CURRENT_REPOSITORY_URL"] = "https://example.com"
    ENV["NOTIFY_TEST_RUN_ID"] = "9999"
    ENV["NOTIFY_APP_NAME"] = "Example App" # Defaults to your Rails app name
    require "chat_notifier"

    failure = ChatNotifier::DebugExceptionLocation.new(location: "fake/path.rb")
    summary = ChatNotifier::DebugSummary.new(failed_examples: [failure])

    ChatNotifier.debug!(ENV, summary:)
  end
end
```

## Contributing

This gem is managed with [Reissue](https://github.com/SOFware/reissue). Releases are automated via the [shared release workflow](https://github.com/SOFware/reissue/blob/main/.github/workflows/SHARED_WORKFLOW_README.md). Trigger a release by running the "Release gem to RubyGems.org" workflow from the Actions tab.
