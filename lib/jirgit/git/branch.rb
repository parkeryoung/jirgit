module Jirgit

  module Git

    class Branch

      attr_accessor :name, :commit

      def short_name
        @name.gsub(/refs\/heads\//,'')
      end

      def date
        @date ||= Jirgit::Git.timestamp(commit)
      end

      def committer
        @committer ||= Jirgit::Git.committer(commit)
      end

      def short_commit
        commit[0,6]
      end

    end

  end

end
