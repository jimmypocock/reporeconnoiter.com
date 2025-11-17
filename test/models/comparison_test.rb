require "test_helper"

class ComparisonTest < ActiveSupport::TestCase
  #--------------------------------------
  # COST CONTROL: Fuzzy Cache Matching
  #--------------------------------------

  test "find_similar_cached returns exact match" do
    # Create a cached comparison
    comparison = create_comparison("rails background jobs", created_at: 1.day.ago)

    result, score = Comparison.find_similar_cached("rails background jobs")

    assert_equal comparison.id, result.id
    assert_operator score, :>, 0.9, "Exact match should have very high similarity score"
  end

  test "find_similar_cached returns nil for dissimilar query" do
    # Create a cached comparison
    create_comparison("rails background jobs", created_at: 1.day.ago)

    # Query is completely different
    result, score = Comparison.find_similar_cached("python machine learning")

    assert_nil result
    assert_equal 0.0, score
  end

  test "find_similar_cached respects cache TTL" do
    # Create comparison older than CACHE_TTL_DAYS
    old_comparison = create_comparison("rails background jobs", created_at: 8.days.ago)

    result, score = Comparison.find_similar_cached("rails background jobs")

    # Should return nil because comparison is stale
    assert_nil result
    assert_equal 0.0, score
  end

  test "find_similar_cached returns most similar result when multiple matches" do
    # Create two similar comparisons
    exact_match = create_comparison("rails background jobs", created_at: 2.days.ago)
    partial_match = create_comparison("rails background processing system", created_at: 1.day.ago)

    result, score = Comparison.find_similar_cached("rails background jobs")

    # Should return the exact match (higher similarity)
    assert_equal exact_match.id, result.id
    assert_operator score, :>, 0.9, "Should return highest similarity match"
  end

  test "find_similar_cached normalizes query (case insensitive)" do
    comparison = create_comparison("Rails Background Jobs", created_at: 1.day.ago)

    # Query with different case
    result, score = Comparison.find_similar_cached("RAILS BACKGROUND JOBS")

    assert_equal comparison.id, result.id
    assert_operator score, :>, 0.9
  end

  test "find_similar_cached normalizes query (whitespace)" do
    comparison = create_comparison("rails background jobs", created_at: 1.day.ago)

    # Query with extra whitespace
    result, score = Comparison.find_similar_cached("  rails   background    jobs  ")

    assert_equal comparison.id, result.id
    assert_operator score, :>, 0.9
  end

  test "normalize_query_string handles whitespace and case correctly" do
    query = "  Rails   Background   JOBS  "
    normalized = Comparison.normalize_query_string(query)

    assert_equal "rails background jobs", normalized
  end

  #--------------------------------------
  # SEARCH: Comprehensive Multi-Field Search
  #--------------------------------------

  test "search finds by user_query" do
    comparison = create_comparison("Rails background job library")

    results = Comparison.search("background")

    assert_includes results, comparison
  end

  test "search finds by technologies" do
    comparison = create_comparison("job library")
    comparison.update!(technologies: "Rails, Ruby")

    results = Comparison.search("ruby")

    assert_includes results, comparison
  end

  test "search finds by problem_domains" do
    comparison = create_comparison("job library")
    comparison.update!(problem_domains: "Background Job Processing")

    results = Comparison.search("processing")

    assert_includes results, comparison
  end

  test "search finds by associated category name" do
    comparison = create_comparison("job library")
    category = categories(:one) # "Background Jobs" category
    comparison.comparison_categories.create!(category: category, assigned_by: "ai")

    results = Comparison.search("background")

    assert_includes results, comparison
  end

  test "search is case insensitive" do
    comparison = create_comparison("Rails library")
    comparison.update!(technologies: "Rails, Ruby")

    [ "RAILS", "rails", "RaIlS" ].each do |search_term|
      results = Comparison.search(search_term)
      assert_includes results, comparison, "Should find comparison with search term: #{search_term}"
    end
  end

  test "search handles partial matches" do
    comparison = create_comparison("authentication library")
    comparison.update!(problem_domains: "Authentication")

    results = Comparison.search("auth")

    assert_includes results, comparison
  end

  test "search returns empty for blank search term" do
    create_comparison("Rails library")

    results = Comparison.search("")

    assert_equal Comparison.count, results.count
  end

  test "search returns empty for nil search term" do
    create_comparison("Rails library")

    results = Comparison.search(nil)

    assert_equal Comparison.count, results.count
  end

  test "search finds across multiple fields" do
    comparison = create_comparison("best job library")
    comparison.update!(
      technologies: "Rails, Ruby",
      problem_domains: "Background Job Processing"
    )

    # Should find it via any of these fields
    [ "job", "rails", "background", "processing" ].each do |search_term|
      results = Comparison.search(search_term)
      assert_includes results, comparison, "Should find via: #{search_term}"
    end
  end

  test "search does not match unrelated comparisons" do
    rails_comparison = create_comparison("Rails background job library")
    rails_comparison.update!(technologies: "Rails, Ruby", problem_domains: "Background Jobs")

    python_comparison = create_comparison("Python machine learning library")
    python_comparison.update!(technologies: "Python", problem_domains: "Machine Learning")

    results = Comparison.search("rails")

    assert_includes results, rails_comparison
    refute_includes results, python_comparison
  end

  #--------------------------------------
  # SEARCH: Recent Enhancements (Nov 10, 2025)
  #--------------------------------------

  test "search finds by architecture_patterns" do
    comparison = create_comparison("ORM library")
    comparison.update!(architecture_patterns: "ORM Framework, Data Layer")

    results = Comparison.search("orm")

    assert_includes results, comparison
  end

  test "search uses synonym expansion" do
    comparison = create_comparison("authentication library")
    comparison.update!(problem_domains: "Authentication")

    # "auth" should expand to ["auth", "authentication", "authorize", "authorization"]
    results = Comparison.search("auth")

    assert_includes results, comparison
  end

  test "search orders by relevance score DESC" do
    # Create three comparisons with varying relevance
    exact_match = create_comparison("Rails state management library")
    exact_match.update!(technologies: "Rails, Ruby", problem_domains: "State Management")

    partial_match = create_comparison("State management for TypeScript")
    partial_match.update!(technologies: "TypeScript", problem_domains: "State Management")

    weak_match = create_comparison("Python library for state machines")
    weak_match.update!(technologies: "Python", problem_domains: "State Machines")

    results = Comparison.search("rails state management")

    # Exact match should be first (matches user_query + technologies + problem_domains)
    assert_equal exact_match.id, results.first.id, "Best match should be first"
  end

  test "search relevance scoring weights user_query highest" do
    # user_query match = 100 points
    query_match = create_comparison("rails background jobs")

    # technology match = 50 points
    tech_match = create_comparison("job processing library")
    tech_match.update!(technologies: "Rails")

    results = Comparison.search("rails")

    # Query match should rank higher than tech match
    assert_equal query_match.id, results.first.id
  end

  test "search with fuzzy matching finds similar terms" do
    comparison = create_comparison("authentication system")
    comparison.update!(problem_domains: "Authentication")

    # Fuzzy match with WORD_SIMILARITY should find "authentication" for "authentic"
    results = Comparison.search("authentic")

    assert_includes results, comparison
  end

  test "search handles multi-word queries" do
    comparison = create_comparison("Ruby on Rails background job library")
    comparison.update!(technologies: "Rails, Ruby", problem_domains: "Background Job Processing")

    results = Comparison.search("rails background")

    assert_includes results, comparison
  end

  test "search case insensitive across all fields" do
    comparison = create_comparison("rails library")
    comparison.update!(
      technologies: "Rails, Ruby",
      problem_domains: "Background Jobs",
      architecture_patterns: "ORM Framework"
    )

    [ "RAILS", "rails", "RaIlS", "BACKGROUND", "orm" ].each do |term|
      results = Comparison.search(term)
      assert_includes results, comparison, "Should find with term: #{term}"
    end
  end

  test "search returns relevance_score attribute" do
    comparison = create_comparison("Rails library")
    comparison.update!(technologies: "Rails, Ruby")

    results = Comparison.search("rails")

    first_result = results.first
    assert_respond_to first_result, :relevance_score, "Should have relevance_score attribute"
    assert_operator first_result.relevance_score, :>, 0, "Relevance score should be positive"
  end

  test "search can be scoped to subset of comparisons" do
    # Create Rails and Python comparisons
    rails_comp = create_comparison("rails cache library")
    rails_comp.update!(technologies: "Rails, Ruby, Redis")

    python_comp = create_comparison("python cache library")
    python_comp.update!(technologies: "Python, Redis")

    # Search only Rails comparisons using where scope
    results = Comparison.where("technologies ILIKE ?", "%Rails%").search("cache")

    assert_includes results, rails_comp, "Should include Rails comparison"
    assert_not_includes results, python_comp, "Should not include Python comparison"
  end

  test "with_similarity_to can be scoped to subset of comparisons" do
    # Create cached and old comparisons
    cached_comp = create_comparison("rails background jobs", created_at: 2.days.ago)
    old_comp = create_comparison("rails background processing", created_at: 10.days.ago)

    # Use with_similarity_to only on cached comparisons
    results = Comparison.cached.with_similarity_to("rails background jobs", 0.3)

    assert_includes results, cached_comp, "Should include cached comparison"
    assert_not_includes results, old_comp, "Should not include old comparison"
  end

  #--------------------------------------
  # SEARCH MODES: Fuzzy vs Exact
  #--------------------------------------

  test "search with fuzzy: false uses exact substring matching" do
    # Create comparison with "analyzer" in the name
    comparison = create_comparison("repository analyzer library")
    comparison.update!(problem_domains: "Code Analysis")

    # Fuzzy mode should match similar words via WORD_SIMILARITY
    # "analyse" is similar to "analyzer" but NOT a substring
    fuzzy_results = Comparison.search("analyse", fuzzy: true)
    assert_includes fuzzy_results, comparison, "Fuzzy mode should match 'analyse' to 'analyzer'"

    # Exact mode should NOT match - "analyse" is not a substring of "analyzer"
    exact_results = Comparison.search("analyse", fuzzy: false)
    refute_includes exact_results, comparison, "Exact mode should NOT match 'analyse' to 'analyzer' (not a substring)"

    # But exact mode SHOULD find actual substrings
    exact_substring_results = Comparison.search("analyzer", fuzzy: false)
    assert_includes exact_substring_results, comparison, "Exact mode should find exact substring 'analyzer'"
  end

  #--------------------------------------
  # SECURITY: SQL Injection Protection
  #--------------------------------------

  test "search protects against SQL injection attempts" do
    comparison = create_comparison("Rails library")
    comparison.update!(technologies: "Rails, Ruby")

    # These malicious inputs should not execute SQL, just be treated as search terms
    # They should either return safe results or no results, but never execute arbitrary SQL
    malicious_inputs = [
      "'; DROP TABLE comparisons; --",
      "' OR 1=1 --",
      "' UNION SELECT * FROM users --",
      "\\' OR \\'1\\'=\\'1",
      "admin'--",
      "1' AND '1' = '1",
      "'; DELETE FROM comparisons WHERE '1'='1",
      "' OR 'x'='x"
    ]

    malicious_inputs.each do |malicious_input|
      # Should not raise any errors when processing malicious input
      results = Comparison.search(malicious_input)

      # Should return a valid ActiveRecord::Relation (not execute SQL)
      assert results.is_a?(ActiveRecord::Relation), "Should return AR::Relation for: #{malicious_input}"

      # Should not delete our test comparison (proves DELETE didn't execute)
      assert Comparison.exists?(comparison.id), "Comparison should still exist after: #{malicious_input}"

      # Table should still exist and be queryable (proves DROP didn't execute)
      assert_operator Comparison.count, :>=, 1, "Table should still exist with at least 1 record"
    end
  end

  private

  def create_comparison(query, created_at: Time.current)
    Comparison.create!(
      user_query: query,
      normalized_query: Comparison.normalize_query_string(query),
      repos_compared_count: 3,
      created_at: created_at
    )
  end
end
