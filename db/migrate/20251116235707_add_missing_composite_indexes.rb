class AddMissingCompositeIndexes < ActiveRecord::Migration[8.1]
  def change
    # Composite index for profile endpoint query:
    # current_user.analyses.where(type: "AnalysisDeep").order(created_at: :desc).limit(20)
    # Improves performance by allowing index-only scan for filtering + sorting
    add_index :analyses, [ :user_id, :type, :created_at ],
              name: "index_analyses_on_user_id_type_created_at"

    # Composite index for user stats queries:
    # analyses.where(user_id: X).where("created_at >= ?", date).count/sum
    # Enables efficient date range filtering per user
    add_index :analyses, [ :user_id, :created_at ],
              name: "index_analyses_on_user_id_and_created_at"

    # Composite index for comparison stats queries:
    # comparisons.where(user_id: X).where("created_at >= ?", date).count
    # Enables efficient date range filtering per user (rate limiting, monthly stats)
    add_index :comparisons, [ :user_id, :created_at ],
              name: "index_comparisons_on_user_id_and_created_at"

    # Composite index for budget tracking query:
    # AnalysisStatus.where(status: :processing).where("created_at >= ?", today)
    # Critical for preventing budget overruns by tracking pending costs
    add_index :analysis_statuses, [ :status, :created_at ],
              name: "index_analysis_statuses_on_status_and_created_at"
  end
end
