# Continuous Integration (CI) Tasks
#
# Run locally before pushing to catch failures early.
# Mirrors the GitHub Actions workflow for consistency.
#
# Examples:
#   bin/rails ci:all         # Run all checks (security + lint + tests)
#   bin/rails ci:security    # Run security scans only (Brakeman, Bundler Audit, Importmap)
#   bin/rails ci:lint        # Run RuboCop linter only
#   bin/rails ci:test        # Run all tests only (unit + system)

namespace :ci do
  desc "Run all CI checks (security, lint, tests)"
  task all: %w[ci:security ci:lint ci:test]

  desc "Run security scans (Brakeman, Bundler Audit, Importmap)"
  task :security do
    puts "\n🔒 Running security scans..."
    sh "bin/brakeman --no-pager"
    sh "bin/bundler-audit"
    sh "bin/importmap audit"
  end

  desc "Run RuboCop linter"
  task :lint do
    puts "\n✨ Running linter..."
    sh "bin/rubocop"
  end

  desc "Run all tests (unit + system)"
  task :test do
    puts "\n🧪 Running tests..."
    sh "bin/rails db:test:prepare"
    sh "bin/rails test"
    # sh "bin/rails test:system" # No longer needed after moving to strictly API
  end
end
