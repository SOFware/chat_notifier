module Minitest
  def self.plugin_chat_notifier_init(options)
    require "chat_notifier"
    Minitest.reporter << ChatNotifierPlugin.new(options[:io], options)
  end

  class ChatNotifierPlugin < SummaryReporter
    ExceptionLocation = Data.define(:location)
    Summary = Data.define(:failed_examples)
    def report
      summary = Summary[(results.map{ |result| ExceptionLocation[result.source_location] })]
      ::ChatNotifier.call(summary:)
    end
  end
end