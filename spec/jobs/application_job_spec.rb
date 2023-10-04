# frozen_string_literal: false

describe ApplicationJob, type: :job do
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

    let(:timeout_job_class) do
      stub_const "TimeoutJob", Class.new(described_class)
      TimeoutJob.class_eval do
        queue_as :custom_queue

        def perform; end
      end
      TimeoutJob
    end

    let(:exports_timeout_job_class) do
      stub_const "ExportsTimeoutJob", Class.new(ExportJob)
      ExportsTimeoutJob.class_eval do
        def perform; end
      end
      ExportsTimeoutJob
    end

    let(:cron_timeout_job_class) do
      stub_const "CronTimeoutJob", Class.new(CronJob)
      CronTimeoutJob.class_eval do
        def perform; end
      end
      CronTimeoutJob
    end

    stub_sentry_events

    it "reports job metadata to Sentry" do
      job_class.perform_later(123, _some_kw_arg: 456)
      enqueued_job_id = enqueued_jobs.last["job_id"]
      expect { perform_enqueued_jobs }.to change(sentry_events, :size).by(1)

      expect(sentry_events.last.contexts[:job][:job_id]).to eq(enqueued_job_id)
      expect(sentry_events.last.contexts[:job][:queue_name]).to eq("custom_queue")
      expect(sentry_events.last.contexts[:job][:arguments]).to eq([123, { _some_kw_arg: 456 }])

      expect(sentry_events.last.exception.values.first.value).to match("Something unexpected happened (RuntimeError)")
      expect(sentry_events.last.exception.values.first.type).to eq("RuntimeError")
    end

    it "reports job timeout to Sentry for custom_queue" do
      allow(Timeout).to receive(:timeout).with(30.seconds).and_raise(Timeout::Error)

      timeout_job_class.perform_later
      enqueued_job_id = enqueued_jobs.last["job_id"]
      expect { perform_enqueued_jobs }.to change(sentry_events, :size).by(1)

      expect(sentry_events.last.contexts[:job][:job_id]).to eq(enqueued_job_id)
      expect(sentry_events.last.contexts[:job][:queue_name]).to eq("custom_queue")
      expect(sentry_events.last.exception.values.first.value).to match("Timeout::Error (Timeout::Error)")
      expect(sentry_events.last.exception.values.first.type).to eq("Timeout::Error")
    end

    it "reports exports job timeout to Sentry for exports queue" do
      allow(Timeout).to receive(:timeout).with(5.minutes).and_raise(Timeout::Error)

      exports_timeout_job_class.perform_later
      enqueued_job_id = enqueued_jobs.last["job_id"]
      expect { perform_enqueued_jobs }.to change(sentry_events, :size).by(1)

      expect(sentry_events.last.contexts[:job][:job_id]).to eq(enqueued_job_id)
      expect(sentry_events.last.contexts[:job][:queue_name]).to eq("exports")
      expect(sentry_events.last.exception.values.first.value).to match("Timeout::Error (Timeout::Error)")
      expect(sentry_events.last.exception.values.first.type).to eq("Timeout::Error")
    end

    it "reports cron job timeout to Sentry for cron queue" do
      allow(Timeout).to receive(:timeout).with(1.hour).and_raise(Timeout::Error)

      cron_timeout_job_class.perform_later
      enqueued_job_id = enqueued_jobs.last["job_id"]
      expect { perform_enqueued_jobs }.to change(sentry_events, :size).by(1)

      expect(sentry_events.last.contexts[:job][:job_id]).to eq(enqueued_job_id)
      expect(sentry_events.last.contexts[:job][:queue_name]).to eq("cron")
      expect(sentry_events.last.exception.values.first.value).to match("Timeout::Error (Timeout::Error)")
      expect(sentry_events.last.exception.values.first.type).to eq("Timeout::Error")
    end
  end
end
