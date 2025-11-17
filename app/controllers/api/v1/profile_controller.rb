# API v1 Profile Controller
# Requires user JWT authentication (X-User-Token header)
#
# Endpoints:
#   GET /api/v1/profile - Get current user profile and usage stats
#
module Api
  module V1
    class ProfileController < BaseController
      # Requires both API key and user JWT
      before_action :authenticate_user_token!

      #--------------------------------------
      # ACTIONS
      #--------------------------------------

      # GET /api/v1/profile
      # Returns current user information and usage statistics
      #
      # Headers:
      #   Authorization: Bearer <API_KEY>
      #   X-User-Token: <JWT>
      #
      # Response (200 OK):
      #   {
      #     "data": {
      #       "user": {
      #         "id": 1,
      #         "email": "user@example.com",
      #         "github_username": "johndoe",
      #         "github_id": 12345678,
      #         "github_avatar_url": "https://avatars.githubusercontent.com/u/12345678",
      #         "admin": false
      #       },
      #       "stats": {
      #         "comparisons_this_month": 5,
      #         "analyses_this_month": 2,
      #         "remaining_comparisons_today": 20,
      #         "remaining_analyses_today": 8,
      #         "total_cost_spent": 0.15
      #       },
      #       "recent_comparisons": [...],
      #       "recent_analyses": [...]
      #     }
      #   }
      #
      def show
        # Fetch recent activity
        recent_comparisons = current_user.comparisons.order(created_at: :desc).limit(20)
        recent_analyses = current_user.analyses.where(type: "AnalysisDeep").includes(:repository).order(created_at: :desc).limit(20)

        render_success(
          data: {
            user: {
              id: current_user.id,
              email: current_user.email,
              github_username: current_user.github_username,
              github_id: current_user.github_id,
              github_avatar_url: current_user.github_avatar_url,
              admin: current_user.admin?
            },
            stats: {
              comparisons_this_month: current_user.comparisons_count_this_month,
              analyses_this_month: current_user.analyses_count_this_month,
              remaining_comparisons_today: current_user.remaining_comparisons_today,
              remaining_analyses_today: current_user.remaining_analyses_today,
              total_cost_spent: current_user.total_ai_cost_spent.round(2)
            },
            recent_comparisons: recent_comparisons.map { |c| comparison_summary(c) },
            recent_analyses: recent_analyses.map { |a| analysis_summary(a) }
          }
        )
      end

      private

      #--------------------------------------
      # PRIVATE METHODS
      #--------------------------------------

      def comparison_summary(comparison)
        {
          id: comparison.id,
          user_query: comparison.user_query,
          repos_compared_count: comparison.repos_compared_count,
          created_at: comparison.created_at.iso8601
        }
      end

      def analysis_summary(analysis)
        {
          id: analysis.id,
          repository_name: analysis.repository.full_name,
          model_used: analysis.model_used,
          created_at: analysis.created_at.iso8601
        }
      end
    end
  end
end
