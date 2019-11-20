describe "User can manage their rdvs" do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }

  before do
    visit new_user_session_path
    sign_in(user)
  end

  context "when cancellable" do
    let!(:rdv) { create(:rdv, users: [user], organisation: organisation, starts_at: 5.hours.from_now) }

    scenario "default", js: true do
      visit users_rdvs_path
      expect(page).to have_content(rdv.motif.name)
      expect(page).to have_selector('li', text: "Annuler le RDV")
      click_link("Annuler le RDV")
      alert = page.driver.browser.switch_to.alert
      alert.accept
      expect(page).not_to have_content(rdv.motif.name)
    end
  end

  context "when not cancellable" do
    let!(:rdv) { create(:rdv, users: [user], organisation: organisation, starts_at: 4.hours.from_now) }
    let!(:rdv2) { create(:rdv, users: [user], organisation: organisation, starts_at: 4.hours.ago) }

    scenario "default", js: true do
      visit users_rdvs_path
      expect(page).to have_content(rdv.motif.name)
      expect(page).to have_content(rdv2.motif.name)
      expect(page).not_to have_selector('li', text: "Annuler le RDV")
      expect(page).to have_selector('span', text: "Vous ne pouvez plus annuler ce RDV en ligne.")
    end
  end
end
