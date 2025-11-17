require "test_helper"

class ProcessQueuedAnalysisJobTest < ActiveJob::TestCase
  #--------------------------------------
  # SETUP
  #--------------------------------------

  def setup
    @job = ProcessQueuedAnalysisJob.new
  end

  #--------------------------------------
  # BASIC TESTS
  #--------------------------------------

  test "job queues to default queue" do
    assert_equal "default", ProcessQueuedAnalysisJob.new.queue_name
  end

  test "perform calls QueuedAnalysisProcessor.process_batch" do
    # Mock the processor to avoid actual API calls
    QueuedAnalysisProcessor.stub :process_batch, { processed: 0, errors: [] } do
      # Should not raise errors
      assert_nothing_raised do
        @job.perform
      end
    end
  end

  test "perform delegates to QueuedAnalysisProcessor service" do
    called = false

    QueuedAnalysisProcessor.stub :process_batch, ->() { called = true; { processed: 0, errors: [] } } do
      @job.perform
    end

    assert called, "QueuedAnalysisProcessor.process_batch should be called"
  end
end
