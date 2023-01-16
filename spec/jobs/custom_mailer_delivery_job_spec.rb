# frozen_string_literal: true

RSpec.describe CustomMailerDeliveryJob do
  mailer = Class.new(ApplicationMailer) do
    def a_sample_email(absence)
      mail(body: "Voici l'info: #{absence}")
    end
  end

  stub_sentry_events

  it "discards job when deserialization fails because if ActiveRecord::RecordNotFound" do
    absence = create(:absence)
    mailer.a_sample_email(absence).deliver_later
    absence.destroy!
    expect { perform_enqueued_jobs }.not_to raise_error
  end

  # Sometimes we have DB failures, these should not cause the job to be discarded
  it "logs to sentry and retries job when hitting a ActiveJob::DeserializationError error that is not a RecordNotFound" do
    absence = create(:absence)
    mailer.a_sample_email(absence).deliver_later
    expect(enqueued_jobs.last["job_class"]).to eq("CustomMailerDeliveryJob")
    expect(enqueued_jobs.last["executions"]).to eq(0)
    expect(sentry_events).to be_empty

    ActiveRecord::Base.remove_connection # Simulate a DB failure

    perform_enqueued_jobs

    # It logs to Sentry
    expect(sentry_events.last.exception.values.last.type).to eq("ActiveJob::DeserializationError")
    expect(sentry_events.last.exception.values.last.value).to eq("Error while trying to deserialize arguments: No connection pool for 'ActiveRecord::Base' found. (ActiveJob::DeserializationError)")

    # It re-enqueues the job
    expect(enqueued_jobs.last["job_class"]).to eq("CustomMailerDeliveryJob")
    expect(enqueued_jobs.last["executions"]).to eq(1)
    expect(enqueued_jobs.last[:args][1]).to eq("a_sample_email")
    expect(enqueued_jobs.last[:args][3]["args"]).to eq([{ "_aj_globalid" => "gid://lapin/Absence/#{absence.id}" }])

    ActiveRecord::Base.establish_connection # teardown DB failure simulation
  end
end
