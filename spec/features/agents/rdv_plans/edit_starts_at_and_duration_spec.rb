RSpec.describe "Editing starts_at and duration for rdv plans" do
  let!(:organisation) { create(:organisation) }
  let(:application) { create(:oauth_application) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let!(:user) { create(:user, organisations: [organisation]) }

  let(:rdv_plan) do
    create(:rdv_plan, user:, motif:,
                      starts_at: 1.week.from_now,
                      duration_in_minutes: 30,
                      rdv_agent: agent,
                      planning_agent: agent,
                      oauth_application: application)
  end

  before { login_as(agent, scope: :agent) }

  it "allows editing the starts_at and duration of the rdv_plan" do
    visit edit_starts_at_and_duration_agents_rdv_plan_path(rdv_plan.id)
  end
end
