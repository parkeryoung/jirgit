RSpec.shared_context "Test Repository" do

  before do
    @config = Jirgit::Configuration.new("#{`echo ~`.chomp}/.jirgit")
    @config[:jira_url] = "http://test.url"
    @repository = "test_repository"
    @repo = create_test_repository(@repository)
    @js = Jirgit::JiraStore.new("#{@repository}/.git/jirgit/jira_store")
    @log = "#{@repository}/.git/jirgit/hooks.log"
    @debug = false
  end

  after do
    @repo.remove
  end

end
