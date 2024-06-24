RSpec.describe "Agent can manage recurrence on plage d'ouverture" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:motif) { create(:motif, name: "Suivi bonjour", organisation: organisation, service: service, location_type: :phone) }
  let!(:plage_ouverture) { create(:plage_ouverture, agent: agent, organisation: organisation, first_day: Time.zone.local(2019, 12, 3)) }

  before do
    travel_to(Time.zone.local(2019, 12, 2))
    login_as(agent, scope: :agent)
    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
  end

  it "default", js: true do
    expect_page_title("Modifier votre plage d'ouverture")
    expect_not_checked("plage_ouverture_has_recurrence", visible: false)
    expect(page).not_to have_text("Répéter tou(te)s les")

    # fill recurrence form

    check "Suivi bonjour"
    check("plage_ouverture_has_recurrence", visible: :hidden, allow_label_click: true)
    expect(page).to have_text("Répéter tou(te)s les")
    check("plage_ouverture_on_monday")
    check("plage_ouverture_on_tuesday")
    check("plage_ouverture_on_wednesday")
    check("plage_ouverture_on_thursday")
    check("plage_ouverture_on_friday")
    check("plage_ouverture_on_saturday")
    select("Arrêter le (date)", from: "plage_ouverture_until_mode")
    fill_in("plage_ouverture_until", with: "30/12/2019")

    click_button("Enregistrer")

    # check if everything is ok in db
    expect(plage_ouverture.reload.schedule.to_hash).to eq(
      day: [1, 2, 3, 4, 5, 6],
      every: :week,
      interval: 1,
      on: %w[monday tuesday wednesday thursday friday saturday],
      until: Time.zone.local(2019, 12, 30),
      starts: Time.zone.local(2019, 12, 3)
    )

    # reload page to check if form is filled correctly
    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect_checked("plage_ouverture_has_recurrence", visible: false)
    expect_checked("plage_ouverture_on_monday")
    expect_checked("plage_ouverture_on_tuesday")
    expect_checked("plage_ouverture_on_wednesday")
    expect_checked("plage_ouverture_on_thursday")
    expect_checked("plage_ouverture_on_friday")
    expect_checked("plage_ouverture_on_saturday")
    expect(page).to have_field("plage_ouverture_until", with: "30/12/2019")

    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    select("mois", from: "plage_ouverture_every")
    expect(page).not_to have_text("Répéter les")
    # expect(page).to have_text("Tous les 1er mardi du mois")
    fill_in("plage_ouverture_first_day", with: "11/12/2019")
    select("1", from: "plage_ouverture_interval")
    # expect(page).to have_text("Tous les 2ème mercredi du mois")
    click_button("Enregistrer")
    # check if everything is ok in db
    expect(plage_ouverture.reload.schedule.to_hash).to eq(
      day: { 3 => [2] },
      every: :month,
      interval: 1,
      until: Time.zone.local(2019, 12, 30),
      starts: Time.zone.local(2019, 12, 11)
    )

    # reload page to check if form is filled correctly
    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect_checked("plage_ouverture_has_recurrence", visible: false)
    expect(page).to have_select("plage_ouverture_every", selected: "mois")
    expect(page).to have_select("plage_ouverture_interval", selected: "1")
    # expect(page).to have_text("Tous les 2ème mercredi du mois")
    expect(page).to have_field("plage_ouverture_until", with: "30/12/2019")
  end

  def expect_checked(element_selector, visible: true)
    expect(page).to have_field(element_selector, checked: true, visible: visible)
  end

  def expect_not_checked(element_selector, visible: true)
    expect(page).to have_field(element_selector, checked: false, visible: visible)
  end
end
