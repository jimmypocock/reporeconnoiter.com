# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_17_001449) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "ai_costs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "model_used", null: false
    t.decimal "total_cost_usd", precision: 10, scale: 6, default: "0.0"
    t.bigint "total_input_tokens", default: 0
    t.bigint "total_output_tokens", default: 0
    t.integer "total_requests", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["date", "model_used"], name: "index_ai_costs_on_date_and_model_used", unique: true
    t.index ["date"], name: "index_ai_costs_on_date"
    t.index ["user_id"], name: "index_ai_costs_on_user_id"
  end

  create_table "analyses", force: :cascade do |t|
    t.text "adoption_analysis"
    t.string "content_hash"
    t.decimal "cost_usd", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "input_tokens"
    t.boolean "is_current", default: true
    t.text "issues_analysis"
    t.text "key_insights"
    t.text "learning_value"
    t.text "maintenance_analysis"
    t.string "maturity_assessment"
    t.string "model_used", null: false
    t.integer "output_tokens"
    t.jsonb "quality_signals"
    t.text "readme_analysis"
    t.bigint "repository_id", null: false
    t.text "security_analysis"
    t.text "summary"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.text "use_cases"
    t.bigint "user_id"
    t.text "why_care"
    t.index ["cost_usd"], name: "index_analyses_on_cost_usd"
    t.index ["created_at"], name: "index_analyses_on_created_at"
    t.index ["is_current"], name: "index_analyses_on_is_current"
    t.index ["repository_id", "type", "is_current"], name: "index_analyses_current"
    t.index ["repository_id"], name: "index_analyses_on_repository_id"
    t.index ["type"], name: "index_analyses_on_type"
    t.index ["user_id", "created_at"], name: "index_analyses_on_user_id_and_created_at"
    t.index ["user_id", "type", "created_at"], name: "index_analyses_on_user_id_type_created_at"
    t.index ["user_id"], name: "index_analyses_on_user_id"
  end

  create_table "analysis_statuses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.decimal "pending_cost_usd", precision: 10, scale: 6, default: "0.0", null: false
    t.bigint "repository_id"
    t.string "session_id"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["repository_id"], name: "index_analysis_statuses_on_repository_id"
    t.index ["session_id"], name: "index_analysis_statuses_on_session_id", unique: true
    t.index ["status", "created_at"], name: "index_analysis_statuses_on_status_and_created_at"
    t.index ["user_id"], name: "index_analysis_statuses_on_user_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key_digest", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "prefix"
    t.integer "request_count", default: 0, null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["prefix"], name: "index_api_keys_on_prefix"
    t.index ["revoked_at"], name: "index_api_keys_on_revoked_at"
    t.index ["user_id", "revoked_at"], name: "index_api_keys_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "category_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "embedding"
    t.string "name", null: false
    t.integer "repositories_count", default: 0
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["category_type", "repositories_count"], name: "index_categories_on_category_type_and_repositories_count"
    t.index ["category_type"], name: "index_categories_on_category_type"
    t.index ["slug", "category_type"], name: "index_categories_on_slug_and_category_type", unique: true
  end

  create_table "comparison_categories", force: :cascade do |t|
    t.string "assigned_by", default: "inferred"
    t.bigint "category_id", null: false
    t.bigint "comparison_id", null: false
    t.decimal "confidence_score", precision: 3, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_comparison_categories_on_category_id"
    t.index ["comparison_id", "category_id"], name: "index_comparison_categories_on_comparison_id_and_category_id", unique: true
    t.index ["comparison_id"], name: "index_comparison_categories_on_comparison_id"
  end

  create_table "comparison_repositories", force: :cascade do |t|
    t.bigint "comparison_id", null: false
    t.jsonb "cons", default: []
    t.datetime "created_at", null: false
    t.text "fit_reasoning"
    t.jsonb "pros", default: []
    t.integer "rank"
    t.bigint "repository_id", null: false
    t.integer "score"
    t.datetime "updated_at", null: false
    t.index ["comparison_id", "rank"], name: "index_comparison_repositories_on_comparison_id_and_rank"
    t.index ["comparison_id"], name: "index_comparison_repositories_on_comparison_id"
    t.index ["repository_id"], name: "index_comparison_repositories_on_repository_id"
  end

  create_table "comparison_statuses", force: :cascade do |t|
    t.bigint "comparison_id"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.decimal "pending_cost_usd", precision: 10, scale: 6, default: "0.0", null: false
    t.string "session_id", null: false
    t.string "status", default: "processing", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["comparison_id"], name: "index_comparison_statuses_on_comparison_id"
    t.index ["session_id"], name: "index_comparison_statuses_on_session_id", unique: true
    t.index ["user_id"], name: "index_comparison_statuses_on_user_id"
  end

  create_table "comparisons", force: :cascade do |t|
    t.string "architecture_patterns"
    t.jsonb "constraints", default: []
    t.decimal "cost_usd", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.text "github_search_query"
    t.integer "input_tokens"
    t.string "model_used"
    t.string "normalized_query"
    t.integer "output_tokens"
    t.string "problem_domains"
    t.jsonb "ranking_results"
    t.text "recommendation_reasoning"
    t.string "recommended_repo_full_name"
    t.integer "repos_compared_count"
    t.string "session_id"
    t.string "status"
    t.string "technologies"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.text "user_query", null: false
    t.integer "view_count", default: 0
    t.index ["architecture_patterns"], name: "index_comparisons_on_architecture_patterns_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["created_at"], name: "index_comparisons_on_created_at"
    t.index ["normalized_query"], name: "index_comparisons_on_normalized_query_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["problem_domains"], name: "index_comparisons_on_problem_domains"
    t.index ["problem_domains"], name: "index_comparisons_on_problem_domains_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["session_id"], name: "index_comparisons_on_session_id", unique: true
    t.index ["technologies"], name: "index_comparisons_on_technologies_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["user_id", "created_at"], name: "index_comparisons_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_comparisons_on_user_id"
    t.index ["view_count"], name: "index_comparisons_on_view_count"
  end

  create_table "queued_analyses", force: :cascade do |t|
    t.string "analysis_type", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "priority", default: 0
    t.datetime "processed_at"
    t.bigint "repository_id", null: false
    t.integer "retry_count", default: 0
    t.datetime "scheduled_for"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_queued_analyses_on_created_at"
    t.index ["repository_id"], name: "index_queued_analyses_on_repository_id"
    t.index ["status", "priority", "scheduled_for"], name: "index_queued_analyses_processing"
  end

  create_table "repositories", force: :cascade do |t|
    t.boolean "archived", default: false
    t.string "clone_url"
    t.datetime "created_at", null: false
    t.string "default_branch", default: "main"
    t.text "description"
    t.boolean "disabled", default: false
    t.integer "fetch_count", default: 0
    t.integer "forks_count", default: 0
    t.string "full_name", null: false
    t.datetime "github_created_at"
    t.bigint "github_id", null: false
    t.datetime "github_pushed_at"
    t.datetime "github_updated_at"
    t.string "homepage_url"
    t.string "html_url", null: false
    t.boolean "is_fork", default: false
    t.boolean "is_template", default: false
    t.string "language"
    t.datetime "last_analyzed_at"
    t.datetime "last_fetched_at"
    t.string "license"
    t.string "name", null: false
    t.string "node_id", null: false
    t.integer "open_issues_count", default: 0
    t.string "owner_avatar_url"
    t.string "owner_login"
    t.string "owner_type"
    t.text "readme_content"
    t.datetime "readme_fetched_at"
    t.integer "readme_length"
    t.string "readme_sha"
    t.float "search_score"
    t.integer "size"
    t.integer "stargazers_count", default: 0
    t.jsonb "topics", default: []
    t.datetime "updated_at", null: false
    t.string "visibility", default: "public"
    t.integer "watchers_count", default: 0
    t.index ["archived", "disabled"], name: "index_repositories_on_archived_and_disabled"
    t.index ["full_name"], name: "index_repositories_on_full_name", unique: true
    t.index ["github_created_at"], name: "index_repositories_on_github_created_at"
    t.index ["github_id"], name: "index_repositories_on_github_id", unique: true
    t.index ["github_pushed_at"], name: "index_repositories_on_github_pushed_at"
    t.index ["language"], name: "index_repositories_on_language"
    t.index ["last_analyzed_at"], name: "index_repositories_on_last_analyzed_at"
    t.index ["node_id"], name: "index_repositories_on_node_id", unique: true
    t.index ["stargazers_count"], name: "index_repositories_on_stargazers_count"
    t.index ["topics"], name: "index_repositories_on_topics", using: :gin
  end

  create_table "repository_categories", force: :cascade do |t|
    t.string "assigned_by", default: "ai"
    t.bigint "category_id", null: false
    t.float "confidence_score"
    t.datetime "created_at", null: false
    t.bigint "repository_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_repository_categories_on_category_id"
    t.index ["confidence_score"], name: "index_repository_categories_on_confidence_score"
    t.index ["repository_id", "category_id"], name: "index_repo_categories_uniqueness", unique: true
    t.index ["repository_id"], name: "index_repository_categories_on_repository_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "github_avatar_url"
    t.integer "github_id"
    t.string "github_name"
    t.string "github_username"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.bigint "whitelisted_user_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["whitelisted_user_id"], name: "index_users_on_whitelisted_user_id"
  end

  create_table "whitelisted_users", force: :cascade do |t|
    t.string "added_by"
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "github_id"
    t.string "github_username"
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["github_id"], name: "index_whitelisted_users_on_github_id", unique: true
  end

  add_foreign_key "ai_costs", "users"
  add_foreign_key "analyses", "repositories"
  add_foreign_key "analyses", "users"
  add_foreign_key "analysis_statuses", "repositories"
  add_foreign_key "analysis_statuses", "users"
  add_foreign_key "api_keys", "users"
  add_foreign_key "comparison_categories", "categories"
  add_foreign_key "comparison_categories", "comparisons"
  add_foreign_key "comparison_repositories", "comparisons"
  add_foreign_key "comparison_repositories", "repositories"
  add_foreign_key "comparison_statuses", "comparisons"
  add_foreign_key "comparison_statuses", "users"
  add_foreign_key "comparisons", "users"
  add_foreign_key "queued_analyses", "repositories"
  add_foreign_key "repository_categories", "categories"
  add_foreign_key "repository_categories", "repositories"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "whitelisted_users"
end
