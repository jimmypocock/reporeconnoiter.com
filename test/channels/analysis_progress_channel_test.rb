require "test_helper"

class AnalysisProgressChannelTest < ActionCable::Channel::TestCase
  def setup
    @user = users(:one)
    @repository = repositories(:one)
    # Create a valid analysis status for the user
    @analysis_status = AnalysisStatus.create!(
      session_id: SecureRandom.uuid,
      user: @user,
      repository: @repository,
      status: "processing"
    )
    @session_id = @analysis_status.session_id
  end

  test "subscribes with valid session_id and user" do
    stub_connection(current_user: @user)
    subscribe(session_id: @session_id)

    assert subscription.confirmed?
    assert_has_stream "analysis_progress_#{@session_id}"
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

  test "unsubscribes and stops streams" do
    stub_connection(current_user: @user)
    subscribe(session_id: @session_id)

    assert subscription.confirmed?

    perform :unsubscribed

    assert_no_streams
  end

  #--------------------------------------
  # SECURITY: Authorization Tests
  #--------------------------------------

  test "rejects subscription to another user's session" do
    user_a = users(:one)
    user_b = users(:two)
    repository = repositories(:one)

    # User A creates an analysis status
    analysis_status = AnalysisStatus.create!(
      session_id: SecureRandom.uuid,
      user: user_a,
      repository: repository,
      status: "processing"
    )

    # User B tries to subscribe to User A's session
    stub_connection(current_user: user_b)
    subscribe(session_id: analysis_status.session_id)

    # Should be REJECTED
    assert subscription.rejected?, "User B should not be able to subscribe to User A's session"
  end

  test "allows subscription to own session" do
    user_a = users(:one)
    repository = repositories(:one)

    # User A creates an analysis status
    analysis_status = AnalysisStatus.create!(
      session_id: SecureRandom.uuid,
      user: user_a,
      repository: repository,
      status: "processing"
    )

    # User A subscribes to their own session
    stub_connection(current_user: user_a)
    subscribe(session_id: analysis_status.session_id)

    # Should be CONFIRMED
    assert subscription.confirmed?, "User A should be able to subscribe to their own session"
    assert_has_stream "analysis_progress_#{analysis_status.session_id}"
  end
end
