require './spec/spec_helper'
require 'expect'

describe "Repository Commit Behaviors" do

  include_context "Test Repository"

  context "when making a commit" do

    before do
      @repo.make_a_command_line_commit
      checkout_a_new_branch('new_branch', 'PA-12345')
    end

    context "via editor" do

      before do
        @commit = @repo.make_a_commit
      end

      it "adds the related jira to the body of the commit message" do
        @repo.log_for_one_commit(@commit.sha) do |output, input|
          output.expect("PA-12345", 5) do |message|
            expect(message).to_not be nil
          end
        end
      end

      it "contains the commit message on the first line" do
        @repo.oneline_log_for_one_commit(@commit.sha) do |output, input|
          output.expect("Short (50 chars or less) summary", 5) do |message|
            expect(message).to_not be nil
          end
        end
      end

    end

    context "via command line" do

      before do
        @commit = @repo.make_a_command_line_commit
      end

      it "adds the related jira to the body of the commit message" do
        @repo.log_for_one_commit(@commit.sha) do |output, input|
          output.expect("PA-12345", 5) do |message|
            expect(message).to_not be nil
          end
        end
      end

      it "contains the commit message on the first line" do
        @repo.oneline_log_for_one_commit(@commit.sha) do |output, input|
          output.expect("command line specified commit message", 5) do |message|
            expect(message).to_not be nil
          end
        end
      end

    end

  end

end