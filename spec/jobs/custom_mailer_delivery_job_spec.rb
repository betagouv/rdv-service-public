# frozen_string_literal: true

RSpec.describe CustomMailerDeliveryJob do
  mailer = Class.new(ApplicationMailer) do
    def a_sample_email(absence)
      mail(body: "Voici l'info: #{absence}")
    end
  end

  it "discards job when deserialization fails because if ActiveRecord::RecordNotFound" do
    absence = create(:absence)
    mailer.a_sample_email(absence).deliver_later
    absence.destroy!
    expect { perform_enqueued_jobs }.not_to raise_error
  end

  # Sometimes we have DB failures, these should not cause the job to be discarded
  it "raises error when hitting a ActiveJob::DeserializationError error that is not a RecordNotFound" do
    mailer.a_sample_email(create(:absence)).deliver_later
    ActiveRecord::Base.remove_connection # Simulate a DB failure
    expect { perform_enqueued_jobs }.to raise_error(ActiveJob::DeserializationError, /Error while trying to deserialize arguments: No connection pool/)
    ActiveRecord::Base.establish_connection
  end
end
