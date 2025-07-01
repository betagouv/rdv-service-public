RSpec.describe "Un usager peut supprimer son compte" do
  let!(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  context "L’usager a un RDV passé", js: true do # js: true nécessaire pour accepter la modale
    let!(:rdv) { create(:rdv, :past, users: [user]) }

    specify do
      visit root_path
      click_on "Votre compte"
      expect(page).to have_selector("a", text: /Supprimer/)
      page.accept_confirm { click_on "Supprimer" }
      expect(page).to have_text("Votre compte a été supprimé avec succès")
      expect(user.reload).to be_soft_deleted
    end
  end

  context "L’usager a un RDV futur" do
    let!(:rdv) { create(:rdv, starts_at: 3.days.from_now, users: [user]) }

    specify do
      visit root_path
      click_on "Votre compte"
      expect(page).to have_text("Vous ne pouvez pas supprimer votre compte")
      expect(page).to have_no_selector("a", text: /Supprimer/)
    end
  end
end
