# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "chat_notifier"
require "debug"

if ENV["CI"]
  require "simplecov"
  require "simplecov-json"
  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])
  SimpleCov.start
end

require "minitest/autorun"

def mimic(**kwargs)
  m = Minitest::Mock.new
  kwargs.each do |method_name, return_value|
    if return_value.is_a?(Array) && !return_value.empty?
      m.expect(method_name, return_value.shift, return_value)
    else
      m.expect(method_name, return_value)
    end
  end
  m
end
