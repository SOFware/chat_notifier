# frozen_string_literal: true

require "test_helper"
require "chat_notifier/repository"

describe ChatNotifier::Repository do
  let(:settings) { {} }

  describe ".for" do
    describe "when settings contain DEBUG" do
      let(:settings) { {"DEBUG" => true} }

      it "returns an instance of Debug" do
        repository = ChatNotifier::Repository.for(settings)
        expect(repository).must_be_instance_of(ChatNotifier::Repository::Debug)
      end
    end

    describe "when settings do not contain DEBUG" do
      it "returns an instance of Github" do
        repository = ChatNotifier::Repository.for(settings)
        expect(repository).must_be_instance_of(ChatNotifier::Repository::Github)
      end
    end
  end
end
