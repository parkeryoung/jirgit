require 'pty'

module Jirgit

  module Git

    class NoRepositoryError < StandardError;
      def initialize(msg = "No valid Git repository was found in current directory.")
        super
      end
    end

    def self.repository_root
      value = `git rev-parse --show-toplevel 2>&1`.chomp
      raise NoRepositoryError if value=~/Not a git repository/
      value
    end

    def self.current_branch
      value = `git symbolic-ref -q HEAD --short 2>&1`.chomp
      raise NoRepositoryError if value=~/Not a git repository/
      value
    end

    def self.current_commit
      value = `git log -1 --format=%H 2>&1`.chomp
      raise NoRepositoryError if value=~/Not a git repository/
      value
    end

    def self.previous_branch
      value = `git rev-parse --symbolic-full-name --abbrev-ref @{-1} 2>&1`.chomp
      raise NoRepositoryError if value=~/Not a git repository/
      value
    end

    def self.remote
      value = `git config --get remote.origin.url 2>&1`.chomp
      raise NoRepositoryError if value=~/Not a git repository/
      value
    end

    def self.github_branch_url(branch = current_branch)
      return unless remote =~ /github.com/
      remote
        .gsub(/git\@github.com\:/,'https://github.com/')
        .gsub(/.git$/,"/tree/#{branch}")
    end

    def self.github_commit_url(commit)
      return unless remote =~ /github.com/
      remote
        .gsub(/git\@github.com\:/,'https://github.com/')
        .gsub(/.git$/,"/commit/#{commit}")
    end

    def self.remote_branches
      value = `git fetch 2>&1`
      raise NoRepositoryError if value=~/Not a git repository/

      `git ls-remote --heads origin 2>&1`
        .split(/\n/)
        .map(&:chomp)
        .map{ |line| line.split(/\t/) }
        .map{ |entries|
          Branch.new.tap do |branch|
            branch.commit = entries.first
            branch.name = entries.last
          end
        }
        .sort_by{ |branch| branch.date }
        .reverse
    end

    def self.local_branches
      value = `git for-each-ref --sort=-committerdate refs/heads --format="%(objectname) %(refname)" 2>&1`
        .split(/\n/)
        .map(&:chomp)
        .map{ |line| line.split(/ /) }
        .map{ |entries|
          Branch.new.tap do |branch|
            branch.commit = entries.first
            branch.name = entries.last
          end
        }
        .sort_by{ |branch| branch.date }
        .reverse
      raise NoRepositoryError if value=~/Not a git repository/
      value
    end

    def self.timestamp(reference)
      value = `git log -1 --format=%ci #{reference} 2>&1`.chomp
      raise NoRepositoryError if value=~/Not a git repository/
      value
    end

    def self.committer(reference)
      value = `git log -1 --format=%cN #{reference} 2>&1`.chomp
      raise NoRepositoryError if value=~/Not a git repository/
      value
    end

    def self.log
      log = `git log 2>&1`.chomp
      raise NoRepositoryError if log=~/^Not a git repository/
      commits = log.split(/(?=commit [0-9a-f]{40})/)
      commits.map { |commit| Commit.new(commit) }
    end

    class Repository

      def self.create(path)
        Dir.mkdir(path) unless Dir.exists?(path)
        `cd #{path}; git init .` unless File.exists?("#{path}/.git")
        repo = self.new(path)
      end

      def initialize(path)
        self.path = path
      end

      def remove
        `rm -rf #{path}` if Dir.exists?(path)
      end

      def checkout_new_branch(branch, &block)
        run_command("git checkout -b #{branch}", &block)
      end

      def checkout_branch(branch, &block)
        run_command("git checkout #{branch}", &block)
      end

      def checkout_file(file, &block)
        run_command("git checkout #{file}", &block)
      end

      def create(filename, message)
        run_command("echo '#{message}' > #{filename}")
      end

      def add(filename)
        run_command("git add #{filename}")
      end

      def merge(branch, message="", &block)
        number = rand(100)
        run_command("echo '#{message}' > .git_commit_body")
        output = run_command({env: "export GIT_EDITOR=$PWD/spec/git_editor.rb", command:"git merge #{branch}"}, &block)
        run_command("rm .git_commit_body")
        CommitResponse.new(output)
      end

      def commit(message, &block)
        number = rand(100)
        run_command("echo '#{message}' > .git_commit_body")
        output = run_command({env: "export GIT_EDITOR=$PWD/spec/git_editor.rb", command:"git commit"}, &block)
        run_command("rm .git_commit_body")
        CommitResponse.new(output)
      end

      def command_line_commit(message, &block)
        output = run_command("git commit -m '#{message}'", &block)
        CommitResponse.new(output)
      end

      def amended_command_line_commit(message, &block)
        output = run_command("git commit --amend -m '#{message}'", &block)
        CommitResponse.new(output)
      end

      def make_a_commit(&block)
        number = rand(100)
        output = run_command({env: "export GIT_EDITOR=$PWD/spec/git_editor.rb", command:"echo \"#{number}\" > README.md; git add README.md; git commit"}, &block)
        CommitResponse.new(output)
      end

      def make_a_command_line_commit(&block)
        number = rand(100)
        output = run_command("echo \"#{number}\" > README.md; git add README.md; git commit -m 'command line specified commit message #{number}'", &block)
        CommitResponse.new(output)
      end

      def log(&block)
        run_command("git log", &block)
      end

      def log_for_one_commit(sha, &block)
        run_command("git log -n 1 #{sha}", &block)
      end

      def one_line_log(&block)
        run_command("git log --format=oneline", &block)
      end

      def oneline_log_for_one_commit(sha, &block)
        run_command("git log --format=oneline -n 1 #{sha}", &block)
      end

      def current_commit(&block)
        run_command("git log -1 --format=%H", &block)
      end

      def root
        @path
      end

      def origin
        run_command("git remote -v")
      end

      def origin=(path)
        run_command("git remote add origin #{path}")
      end

      private

        attr_accessor :path

        def run_command(command, &block)
          if command.is_a? Hash
            env = command[:env]
            command = command[:command]
            full_command = "#{env}; cd #{path}; #{command} 2>&1"
          else
            full_command = "cd #{path}; #{command} 2>&1"
          end
          if block_given?
            PTY.spawn(full_command) do |output, input|
              sleep(1) #avoid race conditions
              yield output, input
            end
          else
            `#{full_command}`.chomp
          end
        end

    end

  end

end
