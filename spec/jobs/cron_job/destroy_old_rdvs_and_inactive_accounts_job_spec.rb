RSpec.describe CronJob::DestroyOldRdvsAndInactiveAccountsJob do
  let!(:organisation) { create(:organisation) }
  let!(:webhook_endpoint) do
    create(
      :webhook_endpoint,
      organisation: organisation,
      subscriptions: %w[rdv user user_profile agent]
    )
  end

  it "only destroys Rdvs that are more than 2 years old and inactive users created more than 2 years ago" do
    rdv_occurring_25_months_ago = travel_to(25.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }
    rdv_occurring_23_months_ago = travel_to(23.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }
    rdv_occurring_11_months_ago = travel_to(11.months.ago) { create(:rdv, starts_at: Time.zone.today.change(hour: 16)) }

    user_without_rdv_created_23_months_ago = travel_to(23.months.ago) { create(:user) }

    user_without_rdv_created_25_months_ago = travel_to(25.months.ago) { create(:user) }

    user_created_25_months_ago_with_a_relative_that_has_a_rdv = travel_to(25.months.ago) { create(:user) }
    relative = create(:user, responsible: user_created_25_months_ago_with_a_relative_that_has_a_rdv)
    create(:rdv, users: [relative])

    other_relative = create(:user, responsible: user_created_25_months_ago_with_a_relative_that_has_a_rdv)

    user_created_25_months_ago_with_a_relative_without_a_rdv, = travel_to(25.months.ago) { create(:user) }
    relative_without_rdv = create(:user, responsible: user_created_25_months_ago_with_a_relative_without_a_rdv)

    described_class.new.perform
    perform_enqueued_jobs # to perform the DestroyInactiveUsers job

    expect(Rdv.all).to include(rdv_occurring_23_months_ago, rdv_occurring_11_months_ago)
    expect(Rdv.all).not_to include(rdv_occurring_25_months_ago)

    expect(User.all).to match_array([
                                      user_without_rdv_created_23_months_ago,
                                      user_created_25_months_ago_with_a_relative_that_has_a_rdv,
                                      relative,
                                      other_relative,
                                      user_created_25_months_ago_with_a_relative_without_a_rdv,
                                      relative_without_rdv,
                                      rdv_occurring_11_months_ago.users.first,
                                      rdv_occurring_23_months_ago.users.first,
                                    ])

    expect(User.all).not_to include(user_without_rdv_created_25_months_ago)
  end

  it "calls the webhooks" do
    travel_to(25.months.ago) { create(:rdv, organisation: organisation, starts_at: Time.zone.today.change(hour: 16)) }
    expect do
      described_class.new.perform
    end.to have_enqueued_job(WebhookJob).with(json_payload_with_meta("webhook_reason", "rgpd"), webhook_endpoint.id)
  end
end
