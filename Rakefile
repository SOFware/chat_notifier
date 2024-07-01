# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test

task :self do
  ENV["NOTIFY_APP_NAME"] = "Chat Notifier"
end

Rake::Task["test"].enhance(["self"])

require "reissue/gem"

Reissue::Task.create :reissue do |task|
  # Required: The file to update with the new version number.
  task.version_file = "lib/chat_notifier/version.rb"
end