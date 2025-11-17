require "test_helper"

module Api
  module V1
    class ProfileControllerTest < ActionDispatch::IntegrationTest
      #--------------------------------------
      # SETUP
      #--------------------------------------

      def setup
        # Create a test API key
        result = ApiKey.generate(name: "Test API Key")
        @api_key = result[:api_key]
        @raw_key = result[:raw_key]

        # Create test user
        @user = users(:one)
      end

      def teardown
        @api_key&.destroy
      end

      # Helper to add Authorization header
      def auth_headers
        { "Authorization" => "Bearer #{@raw_key}" }
      end

      # Helper to add user JWT token
      def user_headers(user = @user)
        jwt = JsonWebToken.encode({ user_id: user.id })
        auth_headers.merge("X-User-Token" => jwt)
      end

      #--------------------------------------
      # AUTHENTICATION TESTS
      #--------------------------------------

      test "GET /api/v1/profile requires API key" do
        get v1_profile_path, as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "API key required", json["error"]["message"]
      end

      test "GET /api/v1/profile requires user JWT token" do
        get v1_profile_path, headers: auth_headers, as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "User authentication required", json["error"]["message"]
      end

      test "GET /api/v1/profile accepts valid API key + JWT" do
        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
      end

      #--------------------------------------
      # PROFILE DATA TESTS
      #--------------------------------------

      test "GET /api/v1/profile returns user information" do
        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        user_data = json["data"]["user"]

        assert_equal @user.id, user_data["id"]
        assert_equal @user.email, user_data["email"]
        assert_equal @user.github_username, user_data["github_username"]
        assert_equal @user.github_id, user_data["github_id"]
        assert_equal @user.github_avatar_url, user_data["github_avatar_url"]
        assert_equal @user.admin?, user_data["admin"]
      end

      test "GET /api/v1/profile returns usage stats" do
        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        stats = json["data"]["stats"]

        assert stats.key?("comparisons_this_month")
        assert stats.key?("analyses_this_month")
        assert stats.key?("remaining_comparisons_today")
        assert stats.key?("remaining_analyses_today")
        assert stats.key?("total_cost_spent")

        # Stats should be numeric
        assert_kind_of Integer, stats["comparisons_this_month"]
        assert_kind_of Integer, stats["analyses_this_month"]
        assert_kind_of Numeric, stats["total_cost_spent"]
      end

      test "GET /api/v1/profile returns recent comparisons" do
        # Create a comparison for this user
        comparison = Comparison.create!(
          user_query: "Test query",
          normalized_query: "test",
          repos_compared_count: 3
        )
        @user.comparisons << comparison

        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        recent_comparisons = json["data"]["recent_comparisons"]

        assert recent_comparisons.is_a?(Array)
        # Find our comparison in the list
        our_comparison = recent_comparisons.find { |c| c["id"] == comparison.id }
        assert_not_nil our_comparison
        assert_equal "Test query", our_comparison["user_query"]
        assert_equal 3, our_comparison["repos_compared_count"]
        assert our_comparison.key?("created_at")
      end

      test "GET /api/v1/profile returns recent analyses" do
        # Create a repository and analysis
        repo = repositories(:one)
        analysis = AnalysisDeep.create!(
          repository: repo,
          user: @user,
          model_used: "gpt-5-mini",
          readme_analysis: "Test analysis",
          input_tokens: 100,
          output_tokens: 50,
          is_current: true
        )

        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        recent_analyses = json["data"]["recent_analyses"]

        assert recent_analyses.is_a?(Array)
        # Find our analysis in the list
        our_analysis = recent_analyses.find { |a| a["id"] == analysis.id }
        assert_not_nil our_analysis
        assert_equal repo.full_name, our_analysis["repository_name"]
        assert_equal "gpt-5-mini", our_analysis["model_used"]
        assert our_analysis.key?("created_at")
      end

      test "GET /api/v1/profile limits recent items to 20" do
        # Create 25 comparisons
        25.times do |i|
          comparison = Comparison.create!(
            user_query: "Query #{i}",
            normalized_query: "query #{i}",
            repos_compared_count: 1
          )
          @user.comparisons << comparison
        end

        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        recent_comparisons = json["data"]["recent_comparisons"]

        assert_equal 20, recent_comparisons.size
      end

      #--------------------------------------
      # PERFORMANCE TESTS
      #--------------------------------------

      test "GET /api/v1/profile does not cause N+1 queries for recent analyses" do
        # Create 5 repositories and analyses
        repos = 5.times.map do |i|
          Repository.create!(
            full_name: "test/repo-#{i}",
            name: "repo-#{i}",
            github_id: 100000 + i,
            node_id: "node_#{i}",
            html_url: "https://github.com/test/repo-#{i}",
            owner_login: "test",
            description: "Test repository #{i}",
            stargazers_count: 100,
            language: "Ruby"
          )
        end

        repos.each do |repo|
          AnalysisDeep.create!(
            repository: repo,
            user: @user,
            model_used: "gpt-5-mini",
            readme_analysis: "Test analysis",
            input_tokens: 100,
            output_tokens: 50,
            is_current: true
          )
        end

        # Count queries during the request
        queries = []
        query_counter = ->(name, started, finished, unique_id, payload) {
          # Skip SCHEMA, CACHE, and transaction queries
          unless [ "SCHEMA", "CACHE" ].include?(payload[:name]) || payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT)/
            queries << payload[:sql]
          end
        }

        ActiveSupport::Notifications.subscribed(query_counter, "sql.active_record") do
          get v1_profile_path, headers: user_headers, as: :json
        end

        assert_response :success

        # Debug: Print all queries (uncomment to debug)
        # puts "\n=== All Queries (#{queries.size} total) ==="
        # queries.each_with_index { |q, i| puts "#{i + 1}. #{q}" }

        # Count queries related to fetching analyses and repositories
        # Look for the specific query pattern that fetches recent analyses
        recent_analyses_query = queries.select { |q|
          q.include?('FROM "analyses"') &&
          q.include?('"analyses"."type"') &&
          q.include?('ORDER BY "analyses"."created_at" DESC')
        }

        # Look for individual repository queries (the N+1 problem)
        # Each query looks like: SELECT "repositories".* FROM "repositories" WHERE "repositories"."id" = $1 LIMIT $2
        individual_repository_queries = queries.select { |q|
          q.include?('FROM "repositories"') &&
          q.include?('"repositories"."id" = $1') &&
          q.include?("LIMIT $2")
        }

        # Should have:
        # - 1 query to fetch recent analyses
        # - With N+1: 5 individual repository queries (one per analysis) - this is the BUG
        # - Without N+1: 1 batched repository query with IN clause (after fix)

        assert_equal 1, recent_analyses_query.size, "Should only fetch recent analyses once"

        # After fix with .includes(:repository), should use batched query instead of N individual queries
        assert_equal 0, individual_repository_queries.size,
          "Should NOT have N+1 queries for repositories. Expected 0 individual queries (using batched IN query instead), " \
          "got #{individual_repository_queries.size} queries."

        # Verify the response includes repository names (proves eager loading worked)
        json = JSON.parse(response.body)
        recent_analyses = json["data"]["recent_analyses"]
        assert_equal 5, recent_analyses.size
        recent_analyses.each do |analysis|
          assert analysis["repository_name"].present?, "Repository name should be present"
        end
      end
    end
  end
end
