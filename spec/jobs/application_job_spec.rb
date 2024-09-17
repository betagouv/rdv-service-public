RSpec.describe ApplicationJob, type: :job do
  describe "error logging" do
    let(:job_class) do
      stub_const "MyJob", Class.new(described_class)
      MyJob.class_eval do
        queue_as :custom_queue

        def perform(_some_positional_arg, _some_kw_arg:)
          raise "Something unexpected happened"
        end
      end
      MyJob
    end

    it "reports job metadata to Sentry" do
      job_class.perform_later(123, _some_kw_arg: 456)
      enqueued_job_id = enqueued_jobs.last["job_id"]
      expect { perform_enqueued_jobs }.to change(sentry_events, :size).by(1)

      expect(sentry_events.last.level).to eq(:warning)
      expect(sentry_events.last.contexts[:job][:job_id]).to eq(enqueued_job_id)
      expect(sentry_events.last.contexts[:job][:arguments]).to eq([123, { _some_kw_arg: 456 }])
      expect(sentry_events.last.contexts[:job][:queue_name]).to eq("custom_queue")
      expect(sentry_events.last.contexts[:job][:job_link]).to match("/super_admins/good_job/jobs/#{enqueued_job_id}")

      expect(sentry_events.last.exception.values.first.value).to match("Something unexpected happened (RuntimeError)")
      expect(sentry_events.last.exception.values.first.type).to eq("RuntimeError")
    end
  end

  context "when job disables arguments logging" do
    let(:job_class) do
      stub_const "SensitiveJob", Class.new(described_class)
      SensitiveJob.class_eval do
        self.log_arguments = false

        def perform(_some_positional_arg, _some_kw_arg:) = raise "Something unexpected happened"
      end
      SensitiveJob
    end

    it "does not report arguments to Sentry" do
      job_class.perform_later(123, _some_kw_arg: 456)
      expect { perform_enqueued_jobs }.to change(sentry_events, :size).by(1)
      expect(sentry_events.last.extra[:arguments]).to be_nil
    end
  end

  context "when job disables Sentry warning on retries" do
    let(:job_class) do
      stub_const "SensitiveJob", Class.new(described_class)
      SensitiveJob.class_eval do
        def perform = raise "Something unexpected happened"

        def capture_sentry_warning_for_retry?(_exception) = false
      end
      SensitiveJob
    end

    it "does not report anything to Sentry" do
      job_class.perform_later
      expect { perform_enqueued_jobs }.not_to change(sentry_events, :size)
    end
  end
end
