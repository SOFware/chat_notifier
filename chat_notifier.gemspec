# frozen_string_literal: true

require_relative "lib/chat_notifier/version"

Gem::Specification.new do |spec|
  spec.name = "chat_notifier"
  spec.version = ChatNotifier::VERSION
  spec.authors = ["Jim Gay", "Savannah Albanez"]
  spec.email = ["jim@saturnflyer.com", "sealbanez@gmail.com"]

  spec.summary = "Notify chat of test results"
  spec.description = "Send test results to chat"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["source_code_uri"] = "https://github.com/SOFware/chat_notifier.git"
  spec.metadata["changelog_uri"] = "https://github.com/SOFWare/chat_notifier/blob/master/CHANGELOG.md"

  spec.files = Dir["{lib}/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
