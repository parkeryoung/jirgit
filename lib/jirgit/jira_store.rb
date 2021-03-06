require 'set'

module Jirgit

  class JiraStore

    def initialize(location = "#{Dir.home}/.jira_store")
      self.location = location
    end

    def relate(params)
      tags = extract_tags(params).compact
      vault.relate(*tags)
      vault.save unless params[:save] == false
    end

    def relations(params)
      jira, branch, commit = extract_tags(params).compact.first
      tag = [jira, branch, commit].detect { |tag| !tag.nil? }
      return Set.new unless tag
      vault.load
      vault.relations(tag)
    end

    def reload
      vault.load
    end

    def save
      vault.save
    end

    private

      attr_accessor :location
      attr_reader :vault

      def vault
        @vault ||= Vault.new(location)
      end

      def extract_tags(params)
        jira = branch = commit = nil
        jira = Tag.new(jira: params[:jira]) if params.include?(:jira)
        branch = Tag.new(branch: params[:branch]) if params.include?(:branch)
        commit = Tag.new(commit: params[:commit]) if params.include?(:commit)
        [jira, branch, commit]
      end

  end

end
