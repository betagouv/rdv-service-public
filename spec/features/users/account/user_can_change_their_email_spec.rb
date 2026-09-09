RSpec.describe "L'usager peut changer son email" do
  include_context "enable rack-attack" # en l’activant ici on teste que le cas normal fonctionne aussi

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

    perform_enqueued_jobs
    open_email("nouvelle@adresse.fr")
    expect(current_email.subject).to include("Votre code de confirmation est ")
    code = current_email.subject.match(/Votre code de confirmation est (\d{6})/)[1]
    fill_in "Code à 6 chiffres", with: code
    click_on "Confirmer"

    expect(page).to have_content "Votre adresse email a été mise à jour."
    expect(page).to have_field("Email", with: "nouvelle@adresse.fr", disabled: true)
    expect(user.reload.email).to eq "nouvelle@adresse.fr"
  end

  context "quand l'usager est connecté via FranceConnect" do
    let(:user) { create(:user, :using_france_connect, organisations: [organisation]) }

    it "n'affiche pas le lien de changement d'adresse email et bloque la soumission directe du formulaire" do
      visit edit_user_registration_path
      expect(page).not_to have_link("Changer d’adresse email")
      expect(page).to have_content("Votre compte étant connecté à FranceConnect, la modification de votre adresse email doit se faire directement depuis FranceConnect")

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

  context "quand l'usager est connecté via ProConnect" do
    let(:user) { create(:user, :using_pro_connect, organisations: [organisation]) }

    it "n'affiche pas le lien de changement d'adresse email et bloque la soumission directe du formulaire" do
      visit edit_user_registration_path
      expect(page).not_to have_link("Changer d’adresse email")
      expect(page).to have_content("Pour des raisons de sécurité, votre compte étant connecté à ProConnect, la modification de votre adresse email est impossible")

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

  context "tentatives d’innondations sur la page de saisie de code" do
    it "lève une erreur Rack Attack" do
      visit users_informations_path
      click_link "Changer d’adresse email"

      expect(page).to have_content "Changer d’adresse email"
      fill_in "Nouvelle adresse email", with: "nouvelle@adresse.fr"
      click_on "Recevoir un code de confirmation"

      2.times do
        visit users_email_change_confirmation_path
        fill_in("Code à 6 chiffres", with: "123456")
        click_on "Confirmer"
      end
      visit users_email_change_confirmation_path
      fill_in("Code à 6 chiffres", with: "123456")
      click_on "Confirmer"
      expect(page).to have_content("erreur")
      expect(sentry_events.last.level).to eq(:warning)
      expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
    end
  end
end
