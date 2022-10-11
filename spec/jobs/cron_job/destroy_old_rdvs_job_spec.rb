# frozen_string_literal: true

describe CronJob::DestroyOldRdvsJob do
  it "only destroys Rdvs that are more than 2 years old" do
    rdv_occurring_25_months_ago = travel_to(25.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }
    rdv_occurring_23_months_ago = travel_to(23.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }
    rdv_occurring_11_months_ago = travel_to(11.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }

    described_class.new.perform

    expect(Rdv.all).to include(rdv_occurring_23_months_ago, rdv_occurring_11_months_ago)
    expect(Rdv.all).not_to include(rdv_occurring_25_months_ago)
  end

  it "does not call any webhook" do
    travel_to(25.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }
    expect do
      described_class.new.perform
    end.not_to have_enqueued_job
  end
end
