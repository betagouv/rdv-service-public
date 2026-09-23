RSpec.describe "Agent can manage recurrence on plage d'ouverture" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, name: "Suivi bonjour", organisation: organisation, location_type: :phone) }

  it "default", js: true do
    plage_ouverture = create(:plage_ouverture, agent: agent, organisation: organisation, first_day: Time.zone.local(2019, 12, 3))
    travel_to(Time.zone.local(2019, 12, 2))
    login_as(agent, scope: :agent)
    visit edit_admin_organisation_planning_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect(find("#radio_recurring", visible: false)).not_to be_checked
    expect(page).not_to have_text("Répéter tou(te)s les")

    # fill recurrence form
    check "Suivi bonjour"
    find('[for="radio_recurring"]').click
    expect(page).to have_text("Répéter tou(te)s les")
    check("recurrence_on_monday")
    check("recurrence_on_tuesday")
    check("recurrence_on_wednesday")
    check("recurrence_on_thursday")
    check("recurrence_on_friday")
    check("recurrence_on_saturday")
    fill_in("recurrence-until", with: "30/12/2019")

    click_button("Enregistrer")
    expect(page).to have_content("La plage d'ouverture a été modifiée")

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
    visit edit_admin_organisation_planning_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect(find("#radio_recurring", visible: false)).to be_checked
    expect_checked("recurrence_on_monday")
    expect_checked("recurrence_on_tuesday")
    expect_checked("recurrence_on_wednesday")
    expect_checked("recurrence_on_thursday")
    expect_checked("recurrence_on_friday")
    expect_checked("recurrence_on_saturday")
    expect(page).to have_field("recurrence-until", with: "30/12/2019")

    visit edit_admin_organisation_planning_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    uncheck("recurrence_on_monday")
    uncheck("recurrence_on_tuesday")
    uncheck("recurrence_on_wednesday")
    uncheck("recurrence_on_thursday")
    uncheck("recurrence_on_friday")
    uncheck("recurrence_on_saturday")

    click_button("Enregistrer")
    expect(page).to have_content("La plage d'ouverture a été modifiée")

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

    visit edit_admin_organisation_planning_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    select("mois", from: "recurrence_every")
    expect(page).not_to have_text("Répéter les")
    expect(page).to have_text("Tous les 1er mardi du mois")
    fill_in("recurrence-source", with: "11/12/2019")
    select("1", from: "recurrence_interval")
    expect(page).to have_text("Tous les 2ème mercredi du mois")
    click_button("Enregistrer")
    expect(page).to have_content("La plage d'ouverture a été modifiée")

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
    visit edit_admin_organisation_planning_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect(find("#radio_recurring", visible: false)).to be_checked
    expect(page).to have_select("recurrence_every", selected: "mois")
    expect(page).to have_select("recurrence_interval", selected: "1")
    expect(page).to have_text("Tous les 2ème mercredi du mois")
    expect(page).to have_field("recurrence-until", with: "30/12/2019")
  end

  context "dans un fuseau horaire à l'offset négatif" do
    it "ne se trompe pas sur le jour de récurrence et de fin (voir #6708)", js: true do
      now = Time.zone.parse("2026-09-15 08:00")
      travel_to(now)

      plage_ouverture = create(:plage_ouverture, agent:, organisation:, first_day: "2026-09-15")

      Capybara.using_driver(:playwright_guadeloupe) do
        page.driver.with_playwright_page { _1.clock.pause_at(now) }
        login_as(agent, scope: :agent)
        visit edit_admin_organisation_planning_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
        check "Suivi bonjour"
        find('[for="radio_recurring"]').click
        expect(page).to have_text("Répéter tou(te)s les")
        select("mois", from: "recurrence_every")
        expect(page).to have_text("Tous les 3ème mardi du mois")
        fill_in("recurrence-source", with: "24/09/2026")
        select("1", from: "recurrence_interval")
        expect(page).to have_text("Tous les 4ème jeudi du mois")
        fill_in("recurrence-until", with: "31/12/2026")
        click_button("Enregistrer")

        # check if everything is ok in db
        expect(plage_ouverture.reload.recurrence.to_hash).to eq(
          day: { 4 => [4] },
          every: :month,
          interval: 1,
          starts: Time.zone.local(2026, 9, 24),
          until: Time.zone.local(2026, 12, 31)
        )

        # reload page to check if form is filled correctly
        visit edit_admin_organisation_planning_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
        expect(page).to have_text("Tous les 4ème jeudi du mois")
        expect(page).to have_field("recurrence-until", with: "31/12/2026")
      end
    end
  end

  def expect_checked(element_selector)
    expect(page).to have_field(element_selector, checked: true)
  end
end
