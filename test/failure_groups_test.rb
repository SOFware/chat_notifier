# frozen_string_literal: true

require "test_helper"
require "chat_notifier/failure_groups"

Loc = Struct.new(:location)

describe ChatNotifier::FailureGroups do
  describe "#reply_texts" do
    it "groups failures in the same file under one heading" do
      failures = [
        Loc.new("test/models/user_test.rb:42"),
        Loc.new("test/models/user_test.rb:88")
      ]

      texts = ChatNotifier::FailureGroups.new(failures).reply_texts

      expect(texts.size).must_equal(1)
      expect(texts.first).must_equal(<<~TEXT.chomp)
        test/models/user_test.rb
          • user_test.rb:42
          • user_test.rb:88
      TEXT
    end

    it "splits files into separate replies once the group size is exceeded" do
      failures = (1..5).map { |n| Loc.new("test/file_#{n}_test.rb:#{n}") }

      texts = ChatNotifier::FailureGroups.new(failures, group_size: 2).reply_texts

      expect(texts.size).must_equal(3)
      expect(texts[0]).must_equal("test/file_1_test.rb\n  • file_1_test.rb:1\ntest/file_2_test.rb\n  • file_2_test.rb:2")
      expect(texts[2]).must_equal("test/file_5_test.rb\n  • file_5_test.rb:5")
    end

    it "normalizes Minitest [file, line] array locations" do
      failures = [Loc.new(["test/order_test.rb", 13])]

      texts = ChatNotifier::FailureGroups.new(failures).reply_texts

      expect(texts.first).must_equal("test/order_test.rb\n  • order_test.rb:13")
    end

    it "starts a new reply when adding a file would exceed the char limit" do
      failures = [
        Loc.new("test/a_test.rb:1"),
        Loc.new("test/b_test.rb:2")
      ]

      texts = ChatNotifier::FailureGroups.new(failures, char_limit: 30).reply_texts

      expect(texts.size).must_equal(2)
    end
  end
end
