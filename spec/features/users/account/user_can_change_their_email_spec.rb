RSpec.describe "L'usager peut changer son email" do
  let!(:organisation) { create(:organisation, territory: create(:territory)) }
  let(:user) { create(:user, email: "ancienne@adresse.fr", organisations: [organisation]) }

  before { login_as(user, scope: :user) }

  it "envoie un code, le valide et modifie l'email" do
    visit users_informations_path
    click_link "Changer d’adresse email"

    expect(page).to have_content "Changer d’adresse email"
    fill_in "Nouvelle adresse email", with: "nouvelle@adresse.fr"
    click_on "Recevoir un code de confirmation"

    expect(page).to have_content "Un code à 6 chiffres a été envoyé à nouvelle@adresse.fr"

    fill_in "Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: "nouvelle@adresse.fr").code
    click_on "Confirmer"

    expect(page).to have_content "Votre adresse email a été mise à jour."
    expect(page).to have_field("Email", with: "nouvelle@adresse.fr", disabled: true)
    expect(user.reload.email).to eq "nouvelle@adresse.fr"
  end

  context "quand l'usager est connecté via FranceConnect" do
    let(:user) { create(:user, :using_france_connect, organisations: [organisation]) }

    it "n'affiche pas le lien de changement d'adresse email et bloque la soumission directe du formulaire" do
      visit users_informations_path
      expect(page).to have_field("Email", with: user.email, disabled: true)
      expect(page).not_to have_link "Changer d’adresse email"

      # l'usager force et accède directement au formulaire (peu probable)
      visit new_email_change_request_path
      fill_in "Nouvelle adresse email", with: "nouvelle@adresse.fr"
      click_on "Recevoir un code de confirmation"

      expect(page).to have_content "Vous ne pouvez pas modifier votre adresse email."
      expect(user.reload.email).not_to eq "nouvelle@adresse.fr"
    end
  end
end
