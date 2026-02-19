RSpec.describe "Un usager peut se logger via un code à 6 chiffres" do
  include_context "enable rack-attack" # en l’activant ici on teste que le cas normal fonctionne aussi

  before { create(:user, email: "marco@lolmail.fr", first_name: "Marco") }

  specify do
    visit new_user_session_path
    fill_in "Adresse email", with: "marco@lolmail.fr"
    click_on "Recevoir un code de connexion"
    expect(page).to have_content("code à 6 chiffres")
    expect(page).to have_content("marco@lolmail.fr")

    perform_enqueued_jobs
    open_email("marco@lolmail.fr")
    expect(current_email.subject).to include("Votre code de connexion est ")
    code = current_email.subject.match(/Votre code de connexion est (\d{6})/)[1]
    fill_in("Code à 6 chiffres", with: code)
    click_on "Valider"

    expect(page).to have_content("Connexion réussie")
    expect(page).to have_current_path("/users/rdvs")
    click_on "Vos informations"
    expect(page).to have_field("user_first_name", with: "Marco")
  end

  context "l’usager rentre une adresse email pour laquelle il n’existe pas de compte usager" do
    specify do
      visit new_user_session_path
      fill_in "Adresse email", with: "nina@personne.fr"
      expect { click_on "Recevoir un code de connexion" }.not_to change(LoginCode, :count)
      expect(page).not_to have_content("code à 6 chiffres")
    end
  end

  context "l’usager demande deux codes en moins de deux minutes" do
    specify do
      visit new_user_session_path
      fill_in "Adresse email", with: "marco@lolmail.fr"
      click_on "Recevoir un code de connexion"
      expect(page).to have_content("Saisie du code")
      click_on "page de connexion"
      fill_in "Adresse email", with: "marco@lolmail.fr"
      expect { click_on "Recevoir un code de connexion" }.not_to change(LoginCode, :count)
      expect(page).to have_content("Un code a été envoyé à marco@lolmail.fr il y a moins de deux minutes")
    end
  end

  context "l’usager rentre un code inexistant" do
    before { create(:login_code, email: "marco@lolmail.fr", code: "123456", created_at: 1.hour.ago) }

    it "ne permet pas de se connecter" do
      visit new_users_sessions_by_code_path(email: "marco@lolmail.fr")
      fill_in("Code à 6 chiffres", with: "992233")
      click_on "Valider"
      expect(page).not_to have_content("Connexion réussie")
      expect(page).to have_content("Code invalide")
    end
  end

  context "l’usager entre un mauvais code puis le bon" do
    before { create(:login_code, email: "marco@lolmail.fr", code: "123456", created_at: 1.minute.ago) }

    specify do
      visit new_users_sessions_by_code_path(email: "marco@lolmail.fr")
      fill_in("Code à 6 chiffres", with: "999999")
      click_on "Valider"
      expect(page).not_to have_content("Connexion réussie")
      expect(page).to have_content("Veuillez renseigner le dernier code qui vous a été envoyé par email")
      fill_in("Code à 6 chiffres", with: "123456")
      click_on "Valider"
      expect(page).to have_content("Connexion réussie")
    end
  end

  context "l’usager attend trop longtemps, le code est expiré" do
    before { create(:login_code, email: "marco@lolmail.fr", code: "123456", created_at: 1.hour.ago) }

    it "ne permet pas de se connecter" do
      visit new_users_sessions_by_code_path(email: "marco@lolmail.fr")
      fill_in("Code à 6 chiffres", with: "123456")
      click_on "Valider"
      expect(page).not_to have_content("Connexion réussie")
      expect(page).to have_content("Code expiré, veuillez en demander un nouveau")
    end
  end

  context "le code a déjà été utilisé" do
    before { create(:login_code, email: "marco@lolmail.fr", code: "123456", created_at: 1.minute.ago, used_at: 30.seconds.ago) }

    it "ne permet pas de se connecter" do
      visit new_users_sessions_by_code_path(email: "marco@lolmail.fr")
      fill_in("Code à 6 chiffres", with: "123456")
      click_on "Valider"
      expect(page).not_to have_content("Connexion réussie")
      expect(page).to have_content("Code déjà utilisé")
    end
  end

  context "plusieurs codes envoyés, l’usager essaie avec un déjà utilisé" do
    before do
      create(:login_code, email: "marco@lolmail.fr", code: "123456", created_at: 2.minutes.ago, used_at: 1.minute.ago)
      create(:login_code, email: "marco@lolmail.fr", code: "998811", created_at: 1.minute.ago)
    end

    it "ne permet pas de se connecter" do
      visit new_users_sessions_by_code_path(email: "marco@lolmail.fr")
      fill_in("Code à 6 chiffres", with: "123456")
      click_on "Valider"
      expect(page).not_to have_content("Connexion réussie")
      expect(page).to have_content("Veuillez renseigner le dernier code qui vous a été envoyé")
    end
  end

  context "plusieurs codes envoyés, l’usager essaie avec un expiré" do
    before do
      create(:login_code, email: "marco@lolmail.fr", code: "123456", created_at: 1.hour.ago)
      create(:login_code, email: "marco@lolmail.fr", code: "998811", created_at: 1.minute.ago)
    end

    it "ne permet pas de se connecter" do
      visit new_users_sessions_by_code_path(email: "marco@lolmail.fr")
      fill_in("Code à 6 chiffres", with: "123456")
      click_on "Valider"
      expect(page).not_to have_content("Connexion réussie")
      expect(page).to have_content("Veuillez renseigner le dernier code qui vous a été envoyé")
    end
  end

  context "plusieurs codes envoyés dont des usés et expirés, l’usager essaie avec un utilisable" do
    before do
      create(:login_code, email: "marco@lolmail.fr", code: "123456", created_at: 1.minute.ago)
      create(:login_code, email: "marco@lolmail.fr", code: "789012", created_at: 2.minutes.ago)
      create(:login_code, email: "marco@lolmail.fr", code: "332211", created_at: 2.minutes.ago, used_at: 1.minute.ago)
      create(:login_code, email: "marco@lolmail.fr", code: "445566", created_at: 1.hour.ago)
    end

    it "permet de se connecter" do
      visit new_users_sessions_by_code_path(email: "marco@lolmail.fr")
      fill_in("Code à 6 chiffres", with: "123456")
      click_on "Valider"
      expect(page).to have_content("Connexion réussie")
    end
  end

  context "tentatives d’innondations sur la page de saisie de code" do
    before { create(:login_code, email: "marco@lolmail.fr", code: "123456", created_at: 1.minute.ago) }

    it "lève une erreur Rack Attack" do
      2.times do
        visit new_users_sessions_by_code_path(email: "marco@lolmail.fr")
        fill_in("Code à 6 chiffres", with: "123456")
        click_on "Valider"
      end
      visit new_users_sessions_by_code_path(email: "marco@lolmail.fr")
      fill_in("Code à 6 chiffres", with: "123456")
      click_on "Valider"
      expect(page).not_to have_content("Connexion réussie")
      expect(page).to have_content("erreur")
      expect(sentry_events.last.level).to eq(:warning)
      expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
    end
  end
end
