RSpec.describe "Recurrence works on plage d'ouverture even in case of a warning caused by a scheduling conflict" do
  before do
    travel_to(Time.zone.local(2019, 12, 2))
    login_as(agent, scope: :agent)
  end

  let!(:plage_ouverture) { create(:plage_ouverture, :weekly_on_monday, motifs: [motif], agent: agent, organisation: organisation, title: "Permanence", first_day: 2.weeks.ago) }
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, name: "Suivi", organisation:, location_type: :phone) }

  it "works", js: true do
    visit new_admin_organisation_planning_plage_ouverture_path(organisation_id: organisation.id)
    find('[for="radio_recurring"]').click
    fill_in("recurrence-until", with: "30/12/2019")
    check("recurrence_on_monday")

    click_button("Créer la plage d'ouverture")
    expect(page).to have_content("Conflit de dates et d'horaires avec d'autres plages d'ouvertures")

    click_on "Confirmer en ignorant les avertissements"

    expect(page).to have_content("Plage d'ouverture créée")

    expect(PlageOuverture.last.recurrence_ends_at.to_date).to eq Date.new(2019, 12, 30)
  end
end
