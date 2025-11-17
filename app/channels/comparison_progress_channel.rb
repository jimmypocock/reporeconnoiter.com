# ComparisonProgressChannel - Real-time progress updates for comparison creation
#
# Streams progress events from CreateComparisonJob to the client browser.
# Uses session_id for stream isolation (multiple concurrent comparisons).
#
# Client subscription example (Stimulus):
#   consumer.subscriptions.create(
#     { channel: "ComparisonProgressChannel", session_id: "abc-123" },
#     { received: (data) => this.updateProgress(data) }
#   )
class ComparisonProgressChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user
    return reject unless params[:session_id].present?

    # Verify ownership: user can only subscribe to their own sessions
    status = ComparisonStatus.find_by(session_id: params[:session_id])
    return reject unless status&.user_id == current_user.id

    stream_from "comparison_progress_#{params[:session_id]}"
  end
end
