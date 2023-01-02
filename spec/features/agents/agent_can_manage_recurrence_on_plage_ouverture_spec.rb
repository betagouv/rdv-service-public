# frozen_string_literal: true

describe "Agent can manage recurrence on plage d'ouverture" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:motif) { create(:motif, name: "Suivi bonjour", organisation: organisation, service: service) }
  let!(:plage_ouverture) { create(:plage_ouverture, agent: agent, organisation: organisation, first_day: Time.zone.local(2019, 12, 3)) }

  before do
    travel_to(Time.zone.local(2019, 12, 2))
    login_as(agent, scope: :agent)
    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
  end

  it "default", js: true do
    expect_page_title("Modifier votre plage d'ouverture")
    expect_not_checked("recurrence_has_recurrence")
    expect(page).not_to have_text("Répéter tou(te)s les")

    # fill recurrence form
    check "Suivi bonjour"
    check("recurrence_has_recurrence")
    expect(page).to have_text("Répéter tou(te)s les")
    check("recurrence_on_monday")
    check("recurrence_on_tuesday")
    check("recurrence_on_wednesday")
    check("recurrence_on_thursday")
    check("recurrence_on_friday")
    check("recurrence_on_saturday")
    fill_in("recurrence-until", with: Date.new(2019, 12, 30))

    click_button("Enregistrer")

    # check if everything is ok in db
    h_recurrence = plage_ouverture.reload.recurrence.to_hash
    expect(h_recurrence[:day]).to eq([1, 2, 3, 4, 5, 6])
    expect(h_recurrence[:every]).to eq(:week)
    expect(h_recurrence[:interval]).to eq(1)
    expect(h_recurrence[:on]).to eq(%w[monday tuesday wednesday thursday friday saturday])
    # problème sur le stockage de la date, qui
    # est transformé en DateTime par Montrose
    # cf https://github.com/betagouv/rdv-solidarites.fr/issues/1339
    expect(h_recurrence[:until].to_date).to eq(Date.new(2019, 12, 30))
    expect(h_recurrence[:starts].to_date).to eq(Date.new(2019, 12, 3))

    # reload page to check if form is filled correctly
    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect_checked("recurrence_has_recurrence")
    expect_checked("recurrence_on_monday")
    expect_checked("recurrence_on_tuesday")
    expect_checked("recurrence_on_wednesday")
    expect_checked("recurrence_on_thursday")
    expect_checked("recurrence_on_friday")
    expect_checked("recurrence_on_saturday")
    expect(page).to have_field("recurrence-until", with: "2019-12-30")

    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    select("mois", from: "recurrence_every")
    expect(page).not_to have_text("Répéter les")
    expect(page).to have_text("Tous les 1er mardi du mois")
    fill_in("recurrence-source", with: Date.new(2019, 12, 11))
    select("1", from: "recurrence_interval")
    expect(page).to have_text("Tous les 2ème mercredi du mois")
    click_button("Enregistrer")

    # check if everything is ok in db
    h_recurrence = plage_ouverture.reload.recurrence.to_hash
    expect(h_recurrence[:day]).to eq({ 3 => [2] })
    expect(h_recurrence[:every]).to eq(:month)
    expect(h_recurrence[:interval]).to eq(1)
    # problème sur le stockage de la date, qui
    # est transformé en DateTime par Montrose
    # cf https://github.com/betagouv/rdv-solidarites.fr/issues/1339
    expect(h_recurrence[:until].to_date).to eq(Date.new(2019, 12, 30))
    expect(h_recurrence[:starts].to_date).to eq(Date.new(2019, 12, 11))

    # reload page to check if form is filled correctly
    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect_checked("recurrence_has_recurrence")
    expect(page).to have_select("recurrence_every", selected: "mois")
    expect(page).to have_select("recurrence_interval", selected: "1")
    expect(page).to have_text("Tous les 2ème mercredi du mois")
    expect(page).to have_field("recurrence-until", with: "2019-12-30")
  end

  def expect_checked(element_selector)
    expect(page).to have_field(element_selector, checked: true)
  end

  def expect_not_checked(element_selector)
    expect(page).to have_field(element_selector, checked: false)
  end
end
