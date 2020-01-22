describe "User can manage their rdvs" do
  let(:rdv) { create(:rdv, starts_at: starts_at) }
  let(:user) { rdv.users.first }

  before do
    login_as(user, scope: :user)
    visit users_rdvs_path
  end

  context "when cancellable" do
    let(:starts_at) { 5.hours.from_now }

    scenario "default", js: true do
      expect(page).to have_content(rdv.motif.name)
      click_link("Annuler le RDV")
      alert = page.driver.browser.switch_to.alert
      alert.accept
      expect(page).to have_selector('.badge', text: "Annulé")
    end
  end

  context "when not cancellable" do
    let(:starts_at) { 4.hours.from_now }

    scenario "default", js: true do
      expect(page).to have_content(rdv.motif.name)
      expect(page).not_to have_selector('li', text: "Annuler le RDV")
      expect(page).to have_selector('p.font-italic', text: "Ce rendez-vous commence dans moins de 4 heures, il n'est plus annulable en ligne.")
    end
  end

  context "when available for file attente" do
    let(:starts_at) { 15.days.from_now }
    scenario "default", js: true do
      expect(page).to have_content("Je souhaite être prévenu si un créneau se libère.")
      check 'active_0'
      expect(page).to have_content("Vous êtes à présent sur la liste d'attente")
      uncheck 'active_0'
      expect(page).to have_content("Vous n'êtes plus sur la liste d'attente")
    end
  end

  context "when not available for file attente" do
    let(:starts_at) { 30.minutes.from_now }
    scenario "default", js: true do
      expect(page).not_to have_content("Je souhaite être prévenu si un créneau se libère.")
    end
  end
end
