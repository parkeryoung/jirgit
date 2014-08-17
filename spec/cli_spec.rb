require './spec/spec_helper'

module Jiragit

  describe Cli do

    before do
      $stdout = StringIO.new
    end

    after(:all) do
      $stdout = STDOUT
    end

    it "should provide help with no command line options" do
      Cli.new([])
      expect($stdout.string).to match(/Commands/)
    end

    context "with a git repository" do
      REPO = 'test_repository'

      before do
        Jiragit::create_repository(REPO)
        Dir.chdir REPO
      end

      after do
        Dir.chdir '..'
        Jiragit::remove_repository(REPO)
      end

      it "should not have hooks installed" do
        cli = Cli.new([])
        expect(Dir.exists?(".git")).to be true
        expect(Dir.exists?(".git/hooks")).to be true
        cli.send(:gem_hook_files).each do |hook|
          expect(File.exists?(".git/hooks/#{hook}")).to be false
        end
      end

      it "should install hooks" do
        cli = Cli.new([:install])
        cli.send(:gem_hook_files).each do |hook|
          expect(File.exists?(".git/hooks/#{hook}")).to be true
        end
      end

      it "should remove installed hooks" do
        cli = Cli.new([:install])
        cli = Cli.new([:remove])
        cli.send(:gem_hook_files).each do |hook|
          expect(File.exists?(".git/hooks/#{hook}")).to be false
        end
      end

    end

  end

end