# frozen_string_literal: true

RSpec.describe CustomMailerDeliveryJob do
  it "discards job when record can't be found" do
    absence = create(:absence)
    Agents::AbsenceMailer.with(absence: absence).absence_created.deliver_later
    absence.destroy!
    expect { perform_enqueued_jobs }.not_to raise_error(ActiveJob::DeserializationError)
  end

  # Sometimes we have DB failures, these should not cause the job to be discarded
  it "raises error when hitting a ActiveJob::DeserializationError error that is not a RecordNotFound" do
    Agents::AbsenceMailer.with(absence: create(:absence)).absence_created.deliver_later
    ActiveRecord::Base.remove_connection # Simulate a DB failure
    expect { perform_enqueued_jobs }.to raise_error(ActiveJob::DeserializationError)
    ActiveRecord::Base.establish_connection
  end
end
