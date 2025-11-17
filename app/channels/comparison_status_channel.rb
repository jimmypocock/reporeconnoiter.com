# ComparisonStatusChannel - Broadcasts comparison creation progress via JSON
#
# API clients subscribe with session_id to receive real-time progress updates.
#
# Usage (JavaScript):
#   const cable = ActionCable.createConsumer('ws://localhost:3001/cable?token=JWT')
#   cable.subscriptions.create(
#     { channel: "ComparisonStatusChannel", session_id: "uuid" },
#     {
#       received(data) {
#         // data.type: "progress" | "complete" | "error"
#         // data.message, data.step, data.percentage, etc.
#       }
#     }
#   )
#
class ComparisonStatusChannel < ApplicationCable::Channel
  def subscribed
    # Require authentication
    return reject unless current_user

    # Ensure session_id parameter is provided
    session_id = params[:session_id]

    if session_id.blank?
      reject
      return
    end

    # Verify ownership: user can only subscribe to their own sessions
    status = ComparisonStatus.find_by(session_id: session_id)
    unless status&.user_id == current_user.id
      reject
      return
    end

    # Stream from the comparison progress channel
    # This receives broadcasts from ComparisonProgressBroadcaster
    stream_from "comparison_progress_#{session_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end
end
