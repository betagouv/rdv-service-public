RSpec.describe "Editing starts_at and duration for rdv plans" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation:) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation:) }

  let(:rdv_plan) do
    create(:rdv_plan, user:, motif:,
                      starts_at: 1.week.from_now,
                      duration_in_minutes: 30,
                      rdv_agent: agent,
                      planning_agent: agent)
  end

  before { login_as(agent, scope: :agent) }

  it "allows editing the duration of the rdv_plan" do
    visit edit_starts_at_and_duration_agents_rdv_plan_path(rdv_plan.id)

    fill_in "Durée du rendez-vous", with: 20

    click_on "Continuer"

    expect(page).to have_content "Où souhaitez-vous faire le rendez-vous ?"

    expect(rdv_plan.reload.duration_in_minutes).to eq 20
  end
end
