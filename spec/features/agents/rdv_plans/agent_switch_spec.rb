RSpec.describe "Changement d'agent" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], first_name: "Francis", last_name: "Factice") }

  let!(:motif) { create(:motif, organisation:, location_type: :phone) }

  let!(:user) { create(:user, organisations: [organisation]) }

  let(:rdv_plan) do
    create(:rdv_plan, user:, motif:,
                      starts_at: 1.week.from_now,
                      duration_in_minutes: 30,
                      rdv_agent: agent,
                      planning_agent: agent)
  end
  let(:now) { Time.zone.parse("2026-09-29 10:00") }

  before do
    login_as(agent, scope: :agent)
    travel_to(now)
    page.driver.with_playwright_page { it.clock.set_fixed_time(now) }
  end

  it "permet de changer l'agent du rendez-vous", js: true do
    visit edit_starts_at_agents_rdv_plan_path(rdv_plan.id)
    select "Francis FACTICE", from: "agent_id"

    Capybara.page.current_window.resize_to(1280, 1300) # Permet de s'assurer que le click de l'action suivante ne sera pas hors de la fenêtre

    page.driver.with_playwright_page do |pw|
      slot = pw.locator('[data-time="11:30:00"]').last
      box = slot.bounding_box
      pw.mouse.click(box["x"] + (box["width"] / 2), box["y"] + (box["height"] / 2))
    end

    expect(page).to have_content("Étape 3 sur 3")

    expect(rdv_plan.reload.rdv_agent).to eq other_agent
  end
end
