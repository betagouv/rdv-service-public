describe "Agent can manage recurrence on plage d'ouverture" do
  let!(:agent) { create(:agent) }
  let!(:plage_ouverture) { create(:plage_ouverture, agent: agent, first_day: Time.zone.local(2019, 12, 3)) }

  before do
    travel_to(Time.zone.local(2019, 12, 2))
    login_as(agent, scope: :agent)
    visit edit_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
  end

  scenario 'default', js: true do
    expect_page_title("Modifier la plage d'ouverture")
    expect_not_checked('recurrence_has_recurrence')
    expect(page).not_to have_text('Répéter tou(te)s les')

    # fill recurrence form
    check('recurrence_has_recurrence')
    expect(page).to have_text('Répéter tou(te)s les')
    check('recurrence_on_monday')
    check('recurrence_on_tuesday')
    check('recurrence_on_wednesday')
    check('recurrence_on_thursday')
    check('recurrence_on_friday')
    check('recurrence_on_saturday')
    fill_in('recurrence-until', with: '30/12/2019')

    click_button('Modifier')

    # check if everything is ok in db
    expect(plage_ouverture.reload.recurrence.to_hash).to eq(
      day: [1, 2, 3, 4, 5, 6],
      every: :week,
      interval: 1,
      on: %w[monday tuesday wednesday thursday friday saturday],
      until: Time.zone.local(2019, 12, 30)
    )

    # reload page to check if form is filled correctly
    visit edit_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect_checked('recurrence_has_recurrence')
    expect_checked('recurrence_on_monday')
    expect_checked('recurrence_on_tuesday')
    expect_checked('recurrence_on_wednesday')
    expect_checked('recurrence_on_thursday')
    expect_checked('recurrence_on_friday')
    expect_checked('recurrence_on_saturday')
    expect(find_field('recurrence-until').value).to eq '2019-12-30'

    visit edit_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    select('mois', from: 'recurrence_every')
    expect(page).not_to have_text('Répéter les')
    expect(page).to have_text('Tous les 1er mardi du mois')
    fill_in('recurrence-source', with: '11/12/2019')
    select('1', from: 'recurrence_interval')
    expect(page).to have_text('Tous les 2ème mercredi du mois')
    click_button('Modifier')

    # check if everything is ok in db
    expect(plage_ouverture.reload.recurrence.to_hash).to eq(
      day: { 3 => [2] },
      every: :month,
      interval: 1,
      until: Time.zone.local(2019, 12, 30)
    )

    # reload page to check if form is filled correctly
    visit edit_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture)
    expect_checked('recurrence_has_recurrence')
    expect(page).to have_select('recurrence_every', selected: 'mois')
    expect(page).to have_select('recurrence_interval', selected: '1')
    expect(page).to have_text('Tous les 2ème mercredi du mois')
    expect(find_field('recurrence-until').value).to eq '2019-12-30'
  end

  def expect_checked(element_selector)
    expect(page).to have_field(element_selector, checked: true)
  end

  def expect_not_checked(element_selector)
    expect(page).to have_field(element_selector, checked: false)
  end
end
