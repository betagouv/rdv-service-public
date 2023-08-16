# frozen_string_literal: true

describe CronJob::DestroyOldRdvsAndInactiveUsersJob do
  it "only destroys Rdvs that are more than 2 years old and inactive users created 2 more than years ago" do
    rdv_occurring_25_months_ago = travel_to(25.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }
    rdv_occurring_23_months_ago = travel_to(23.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }
    rdv_occurring_11_months_ago = travel_to(11.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }

    user_without_rdv_created_23_months_ago = travel_to(23.months.ago) { create(:user) }

    described_class.new.perform
    perform_enqueued_jobs # to perform the DestroyInactiveUsers job

    expect(Rdv.all).to include(rdv_occurring_23_months_ago, rdv_occurring_11_months_ago)
    expect(Rdv.all).not_to include(rdv_occurring_25_months_ago)

    expect(User.all).to match_array([user_without_rdv_created_23_months_ago, rdv_occurring_11_months_ago.users.first, rdv_occurring_23_months_ago.users.first])
  end

  it "does not call any webhook" do
    travel_to(25.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }
    expect do
      described_class.new.perform
    end.not_to have_enqueued_job(WebhookJob)
  end

  it "actually deletes RDVs that were soft_deleted" do
    now = Time.zone.parse("2022-08-30 11:45:00")
    travel_to(now)
    create(:rdv, starts_at: now - 1.day, deleted_at: now)
    travel_to(now + 2.years + 2.minutes)
    expect do
      described_class.new.perform
    end.to change { Rdv.unscoped.count }.from(1).to(0)
  end
end
