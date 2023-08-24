# frozen_string_literal: true

describe CronJob do
  it "deletes old agents" do
    agent_created_25_months_ago_without_warning = travel_to(25.months.ago) { create(:agent) }

    agent_created_25_months_ago_with_warning = travel_to(25.months.ago) { create(:agent) }
    agent_created_25_months_ago_with_warning.update!(account_deletion_warning_sent_at: 33.days.ago)

    two_years_ago = 2.years.ago
    CronJob::WarnInactiveAgentsOfAccountDeletion.new.perform(two_years_ago)
    CronJob::DestroyInactiveAgents.new.perform(two_years_ago)

    expect(Agent.all).to eq [agent_created_25_months_ago_without_warning]

    expect(agent_created_25_months_ago_without_warning.reload.account_deletion_warning_sent_at).to be_present
  end
end
