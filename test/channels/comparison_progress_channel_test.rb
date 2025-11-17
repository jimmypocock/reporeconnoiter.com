require "test_helper"

class ComparisonProgressChannelTest < ActionCable::Channel::TestCase
  def setup
    @user = users(:one)
    # Create a valid comparison status for the user
    @comparison_status = ComparisonStatus.create!(
      session_id: SecureRandom.uuid,
      user: @user,
      status: "processing"
    )
    @session_id = @comparison_status.session_id
  end

  test "subscribes with valid session_id and user" do
    stub_connection(current_user: @user)
    subscribe(session_id: @session_id)

    assert subscription.confirmed?
    assert_has_stream "comparison_progress_#{@session_id}"
  end

  test "rejects subscription without user" do
    stub_connection(current_user: nil)
    subscribe(session_id: @session_id)

    assert subscription.rejected?
  end

  test "rejects subscription without session_id" do
    stub_connection(current_user: @user)
    subscribe

    assert subscription.rejected?
  end

  test "rejects subscription with blank session_id" do
    stub_connection(current_user: @user)
    subscribe(session_id: "")

    assert subscription.rejected?
  end

  #--------------------------------------
  # SECURITY: Authorization Tests
  #--------------------------------------

  test "rejects subscription to another user's session" do
    user_a = users(:one)
    user_b = users(:two)

    # User A creates a comparison status
    comparison_status = ComparisonStatus.create!(
      session_id: SecureRandom.uuid,
      user: user_a,
      status: "processing"
    )

    # User B tries to subscribe to User A's session
    stub_connection(current_user: user_b)
    subscribe(session_id: comparison_status.session_id)

    # Should be REJECTED
    assert subscription.rejected?, "User B should not be able to subscribe to User A's session"
  end

  test "allows subscription to own session" do
    user_a = users(:one)

    # User A creates a comparison status
    comparison_status = ComparisonStatus.create!(
      session_id: SecureRandom.uuid,
      user: user_a,
      status: "processing"
    )

    # User A subscribes to their own session
    stub_connection(current_user: user_a)
    subscribe(session_id: comparison_status.session_id)

    # Should be CONFIRMED
    assert subscription.confirmed?, "User A should be able to subscribe to their own session"
    assert_has_stream "comparison_progress_#{comparison_status.session_id}"
  end
end
