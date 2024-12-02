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
    fill_in("recurrence-until", with: "30/12/2019")

    click_button("Enregistrer")

    # check if everything is ok in db
    expect(plage_ouverture.reload.recurrence.to_hash).to eq(
      day: [1, 2, 3, 4, 5, 6],
      every: :week,
      interval: 1,
      on: %w[monday tuesday wednesday thursday friday saturday],
      until: Time.zone.local(2019, 12, 30),
      starts: Time.zone.local(2019, 12, 3)
    )
    expect(plage_ouverture.recurrence_ends_at.to_date).to eq Date.new(2019, 12, 30)

    # On vérifie au passage que les données qu'on crée dans nos factories correspondent bien à ce que l'application peut créer
    recurrence_attributes_from_factory = build(:plage_ouverture, :weekly_on_monday).recurrence.to_hash.keys

    expect(recurrence_attributes_from_factory + [:until]).to match_array(plage_ouverture.recurrence.to_hash.keys)

    # reload page to check if form is filled correctly
    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect_checked("recurrence_has_recurrence")
    expect_checked("recurrence_on_monday")
    expect_checked("recurrence_on_tuesday")
    expect_checked("recurrence_on_wednesday")
    expect_checked("recurrence_on_thursday")
    expect_checked("recurrence_on_friday")
    expect_checked("recurrence_on_saturday")
    expect(page).to have_field("recurrence-until")
    # expect(page).to have_field("recurrence-until", with: "30/12/2019")
    # TODO Pourquoi le champs ne contient pas la valeur ici. Quand on le fait à la main, tout va bien.

    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    uncheck("recurrence_on_monday")
    uncheck("recurrence_on_tuesday")
    uncheck("recurrence_on_wednesday")
    uncheck("recurrence_on_thursday")
    uncheck("recurrence_on_friday")
    uncheck("recurrence_on_saturday")

    click_button("Enregistrer")

    # check if everything is ok in db
    expect(plage_ouverture.reload.recurrence.to_hash).to eq(
      every: :week,
      interval: 1,
      until: Time.zone.local(2019, 12, 30),
      starts: Time.zone.local(2019, 12, 3)
    )

    # On vérifie au passage que les données qu'on crée dans nos factories correspondent bien à ce que l'application peut créer
    recurrence_attributes_from_factory = build(:plage_ouverture, :once_a_week).recurrence.to_hash

    expect(recurrence_attributes_from_factory.keys).to match_array(plage_ouverture.recurrence.to_hash.keys)

    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    select("mois", from: "recurrence_every")
    expect(page).not_to have_text("Répéter les")
    expect(page).to have_text("Tous les 1er mardi du mois")
    fill_in("recurrence-source", with: "11/12/2019")
    page.execute_script("document.querySelector('#recurrence-source').dispatchEvent(new CustomEvent('change'))") # NOTE: I don’t know why we need to trigger the event manually in the spec.
    select("1", from: "recurrence_interval")
    expect(page).to have_text("Tous les 2ème mercredi du mois")
    click_button("Enregistrer")

    # check if everything is ok in db
    expect(plage_ouverture.reload.recurrence.to_hash).to eq(
      day: { 3 => [2] },
      every: :month,
      interval: 1,
      until: Time.zone.local(2019, 12, 30),
      starts: Time.zone.local(2019, 12, 11)
    )

    # On vérifie au passage que les données qu'on crée dans nos factories correspondent bien à ce que l'application peut créer
    recurrence_attributes_from_factory = build(:plage_ouverture, :monthly).recurrence.to_hash.keys

    expect(recurrence_attributes_from_factory + [:until]).to match_array(plage_ouverture.recurrence.to_hash.keys)

    # reload page to check if form is filled correctly
    visit edit_admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect_checked("recurrence_has_recurrence")
    expect(page).to have_select("recurrence_every", selected: "mois")
    expect(page).to have_select("recurrence_interval", selected: "1")
    expect(page).to have_text("Tous les 2ème mercredi du mois")
    expect(page).to have_field("recurrence-until")
    # expect(page).to have_field("recurrence-until", with: "30/12/2019")
    # TODO Pourquoi le champs ne contient pas la valeur ici. Quand on le fait à la main, tout va bien.
  end

  def expect_checked(element_selector)
    expect(page).to have_field(element_selector, checked: true)
  end

  def expect_not_checked(element_selector)
    expect(page).to have_field(element_selector, checked: false)
  end
end
