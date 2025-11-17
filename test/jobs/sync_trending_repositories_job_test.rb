require "test_helper"

class SyncTrendingRepositoriesJobTest < ActiveJob::TestCase
  #--------------------------------------
  # SETUP
  #--------------------------------------

  def setup
    @job = SyncTrendingRepositoriesJob.new
  end

  #--------------------------------------
  # BASIC TESTS
  #--------------------------------------

  test "job queues to default queue" do
    assert_equal "default", SyncTrendingRepositoriesJob.new.queue_name
  end

  test "perform syncs trending repositories and enqueues analyses" do
    # Mock GitHub API response
    github_results = OpenStruct.new(
      items: [
        OpenStruct.new(
          full_name: "test/repo",
          name: "repo",
          owner: OpenStruct.new(login: "test", avatar_url: "http://example.com/avatar.jpg", type: "User"),
          id: 12345,
          node_id: "node123",
          html_url: "https://github.com/test/repo",
          description: "Test repo",
          stargazers_count: 1000,
          language: "Ruby"
        )
      ]
    )

    # Stub RepositorySyncer to return controlled results
    RepositorySyncer.stub :sync_trending, { repositories: [] } do
      # Should not raise errors
      assert_nothing_raised do
        @job.perform
      end
    end
  end

  test "calculates priority based on stargazers count" do
    repo_low = OpenStruct.new(stargazers_count: 50)
    repo_medium = OpenStruct.new(stargazers_count: 750)
    repo_high = OpenStruct.new(stargazers_count: 15000)

    assert_equal 0, @job.send(:calculate_priority, repo_low)
    assert_equal 4, @job.send(:calculate_priority, repo_medium)
    assert_equal 10, @job.send(:calculate_priority, repo_high)
  end

  test "skips repositories already in queue" do
    repo = repositories(:one)

    # Create a pending queued analysis
    QueuedAnalysis.create!(
      repository: repo,
      analysis_type: "Analysis",
      status: "pending"
    )

    github_item = OpenStruct.new(
      id: repo.github_id,
      full_name: repo.full_name,
      name: repo.name,
      node_id: repo.node_id,
      owner: OpenStruct.new(login: repo.owner_login, avatar_url: nil, type: "User"),
      html_url: repo.html_url,
      description: repo.description,
      stargazers_count: repo.stargazers_count,
      language: repo.language
    )

    # Mock sync_trending to return our existing repo
    result = { repositories: [ repo ] }

    RepositorySyncer.stub :sync_trending, result do
      initial_count = QueuedAnalysis.count

      @job.perform

      # Should not create a duplicate queued analysis
      assert_equal initial_count, QueuedAnalysis.count
    end
  end
end
