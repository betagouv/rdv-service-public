RSpec.describe CronJob::DestroyInactiveAgents do
  before { travel_to Date.new(2024, 1, 1) }

  it "warns and deletes old agents" do
    # agents that will not be modified
    agent_created_12_months_ago_with_warning = travel_to(12.months.ago) { create(:agent, account_deletion_warning_sent_at: Time.zone.now) }
    agent_created_12_months_ago_without_warning = travel_to(12.months.ago) { create(:agent) }

    # agents that will be warned, but not deleted
    agent_created_25_months_ago_without_warning = travel_to(25.months.ago) { create(:agent) }

    # agents that will be deleted
    agent_created_25_months_ago_with_warning = travel_to(25.months.ago) { create(:agent) }
    agent_created_25_months_ago_with_warning.update!(account_deletion_warning_sent_at: 33.days.ago)

    two_years_ago = 2.years.ago
    CronJob::WarnInactiveAgentsOfAccountDeletion.new.perform(two_years_ago)

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to eq([agent_created_25_months_ago_without_warning.email])
    expect(agent_created_25_months_ago_without_warning.reload.account_deletion_warning_sent_at).to be_present

    described_class.new.perform(two_years_ago)

    expect(Agent.all).to contain_exactly(
      agent_created_25_months_ago_without_warning,
      agent_created_12_months_ago_without_warning,
      agent_created_12_months_ago_with_warning
    )
  end
end
