# frozen_string_literal: true

require "test_helper"
require "chat_notifier/chatter"

describe ChatNotifier::Chatter do
  let(:repository) { Object.new }
  let(:environment) { Object.new }

  describe "#verbose?" do
    describe "when NOTIFIER_VERBOSE is not set" do
      it "returns false" do
        refute ChatNotifier::Chatter.new(
          settings: {},
          repository:,
          environment:
        ).verbose?, "verbose? should be false"
      end
    end

    describe "when NOTIFIER_VERBOSE is set" do
      it "returns true" do
        assert ChatNotifier::Chatter.new(
          settings: {"NOTIFIER_VERBOSE" => "true"},
          repository:,
          environment:
        ).verbose?, "verbose? should be true"
      end
    end
  end
end
