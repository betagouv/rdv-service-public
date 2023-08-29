# frozen_string_literal: true

describe CronJob::DestroyInactiveAgents do
  it "warns and deletes old agents" do
    agent_created_25_months_ago_without_warning = travel_to(25.months.ago) { create(:agent) }

    agent_created_25_months_ago_with_warning = travel_to(25.months.ago) { create(:agent) }
    agent_created_25_months_ago_with_warning.update!(account_deletion_warning_sent_at: 33.days.ago)

    agent_created_12_months_ago_with_warning = travel_to(12.months.ago) { create(:agent, account_deletion_warning_sent_at: Time.zone.now) }
    agent_created_12_months_ago_without_warning = travel_to(12.months.ago) { create(:agent) }

    two_years_ago = 2.years.ago
    CronJob::WarnInactiveAgentsOfAccountDeletion.new.perform(two_years_ago)
    described_class.new.perform(two_years_ago)

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to eq([agent_created_25_months_ago_without_warning.email])

    expect(Agent.all).to match_array([
                                       agent_created_25_months_ago_without_warning,
                                       agent_created_12_months_ago_without_warning,
                                       agent_created_12_months_ago_with_warning,
                                     ])

    expect(agent_created_25_months_ago_without_warning.reload.account_deletion_warning_sent_at).to be_present
  end
end
