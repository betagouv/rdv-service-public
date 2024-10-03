RSpec.describe "User signs up and signs in" do
  around { |example| perform_enqueued_jobs { example.run } }

  context "for regular new user" do
    let(:user) { build(:user) }

    it ".sign_up, .confirm, .sign_in and then signs out" do
      visit "http://www.rdv-solidarites-test.localhost/"
      click_link "Se connecter"
      click_link "Je m'inscris"
      fill_in :user_first_name, with: user.first_name
      fill_in :user_last_name, with: user.last_name
      fill_in :user_email, with: user.email
      click_on "Je m'inscris"
      expect(page).to have_current_path(users_pending_registration_path, ignore_query: true)
      expect_flash_info(I18n.t("devise.registrations.signed_up_but_unconfirmed"))
      open_email(user.email)
      current_email.click_link "Confirmer mon compte"
      expect_flash_info(I18n.t("devise.confirmations.confirmed"))
      expect(page).to have_content("Définir mon mot de passe")
      fill_in :password, with: user.password
      click_on "Enregistrer"
      expect_flash_info(I18n.t("devise.passwords.updated")) # auto-connected
      click_link "Déconnexion"
      expect(page).to have_current_path(root_path, ignore_query: true)
    end
  end

  context "for invited user" do
    let(:invited_user) { create(:user, :unconfirmed) }

    it ".sign_up, .invite!, accept_invite and then signs out" do
      visit "http://www.rdv-solidarites-test.localhost/"
      click_link "Se connecter"
      click_link "Je m'inscris"
      fill_in :user_first_name, with: invited_user.first_name
      fill_in :user_last_name, with: invited_user.last_name
      fill_in :user_email, with: invited_user.email
      click_on "Je m'inscris"
      expect(page).to have_current_path(users_pending_registration_path, ignore_query: true)
      expect_flash_info(I18n.t("devise.registrations.signed_up_but_unconfirmed"))
      open_email(invited_user.email)
      current_email.click_link "Accepter l'invitation"
      expect(page).to have_content("Inscription")
      fill_in :password, with: "Rdvservicepublictest1!"
      click_on "Enregistrer"
      expect(page).to have_current_path(root_path, ignore_query: true)
      expect_flash_info(I18n.t("devise.invitations.updated"))
      click_link "Déconnexion"
      expect(page).to have_current_path(root_path, ignore_query: true)
    end
  end

  context "when an unconfirmed user already exists with the given email" do
    let!(:unconfirmed_user) { create(:user, :unconfirmed) }

    it "sends a new invite" do
      visit "http://www.rdv-aide-numerique-test.localhost/"
      click_link "Se connecter"
      click_link "Je m'inscris"
      fill_in :user_first_name, with: unconfirmed_user.first_name
      fill_in :user_last_name, with: unconfirmed_user.last_name
      fill_in :user_email, with: unconfirmed_user.email
      click_on "Je m'inscris"

      open_email(unconfirmed_user.email)
      expect(current_email.subject).to eq("Vous avez été invité sur RDV Aide Numérique")
    end
  end

  context "if agent goes wrong" do
    let!(:agent) { create(:agent, password: "c0rRecthorse!", basic_role_in_organisations: [create(:organisation)]) }

    it ".sign_in as user and be signed in as agent" do
      visit "http://www.rdv-solidarites-test.localhost/"
      click_link "Se connecter"
      within("form") do
        fill_in :user_email, with: agent.email
        fill_in :password, with: agent.password
        click_on "Se connecter"
      end
      expect(page).to have_current_path(admin_organisation_agent_agenda_path(agent.organisations.first, agent), ignore_query: true)
    end

    context "when the agent's password is too weak" do
      let(:agent) do
        build(:agent, password: "tropfaible").tap do |a|
          a.save(validate: false)
        end
      end

      it "shows a warning and advises to change the password" do
        visit new_user_session_path
        fill_in "Email", with: agent.email
        fill_in "password", with: "tropfaible"
        within("main") { click_on "Se connecter" }
        expect(page).to have_content("Votre mot de passe est trop faible")
      end
    end
  end

  def expect_flash_info(message)
    expect(page).to have_selector(".fr-alert.fr-alert--info", text: message)
  end
end
