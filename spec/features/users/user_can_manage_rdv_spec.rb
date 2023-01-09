# frozen_string_literal: true

describe "User can manage their rdvs" do
  let(:rdv) { create(:rdv, starts_at: starts_at) }
  let(:user) { rdv.users.first }

  before do
    login_as(user, scope: :user)
    visit users_rdvs_path
  end

  context "when cancellable" do
    let(:starts_at) { 5.hours.from_now }

    it "default", js: true do
      expect(page).to have_content(rdv.motif_name)
      click_link("Annuler le RDV")
      expect(page).to have_content("Confirmation")
      click_link("Oui, annuler le rendez-vous")
      expect(page).to have_selector(".badge", text: "Annulé")
    end
  end

  context "when not cancellable" do
    let(:starts_at) { 4.hours.from_now }

    it "default", js: true do
      expect(page).to have_content(rdv.motif_name)
      expect(page).not_to have_selector("li", text: "Annuler le RDV")
      expect(page).to have_content("Ce rendez-vous n'est pas annulable en ligne. Prenez contact avec le secrétariat.")
    end
  end

  context "when available for file attente" do
    let(:starts_at) { 15.days.from_now }

    it "default", js: true do
      expect(page).to have_content("Je souhaite être prévenu si un créneau se libère.")
      check "Je souhaite être prévenu si un créneau se libère."
      expect(page).to have_content("Vous êtes à présent sur la liste d'attente")
      uncheck "Je souhaite être prévenu si un créneau se libère."
      expect(page).to have_content("Vous n'êtes plus sur la liste d'attente")
    end
  end

  context "when not available for file attente" do
    let(:starts_at) { 7.days.from_now }

    it "default", js: true do
      expect(page).not_to have_content("Je souhaite être prévenu si un créneau se libère.")
    end
  end
end
