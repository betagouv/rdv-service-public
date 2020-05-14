feature 'User signs up and signs in' do
  include OrganisationsHelper

  let(:user) { build(:user) }
  let(:invited_user) { create(:user, :unconfirmed) }

  context 'through home page' do
    before { visit root_path }

    scenario '.sign_up, .confirm, .sign_in and then signs out' do
      click_link 'Se connecter'
      click_link 'Je m\'inscris'
      sign_up(user)
      expect(current_path).to eq(new_user_session_path)
      expect_flash_info(I18n.t("devise.registrations.signed_up_but_unconfirmed"))
      open_email(user.email)
      current_email.click_link 'Confirmer mon compte'
      expect_flash_info(I18n.t("devise.confirmations.confirmed"))
      sign_in(user)
      expect(current_path).to eq(authenticated_user_root_path)
      expect_flash_info(I18n.t("devise.sessions.signed_in"))
      click_link user.first_name
      click_link 'Se déconnecter'
      expect(current_path).to eq(root_path)
    end

    scenario '.sign_up, .invite!, accept_invite and then signs out' do
      click_link 'Se connecter'
      click_link 'Je m\'inscris'
      sign_up(invited_user)
      expect(current_path).to eq(new_user_session_path)
      expect_flash_info(I18n.t("devise.registrations.signed_up_but_unconfirmed"))
      open_email(invited_user.email)
      current_email.click_link "Accepter l'invitation"
      expect(page).to have_content('Inscription')
      fill_in :password, with: "123456"
      click_on "Enregistrer"
      expect(current_path).to eq(root_path)
      expect_flash_info(I18n.t("devise.invitations.updated"))
      click_link invited_user.first_name
      click_link 'Se déconnecter'
      expect(current_path).to eq(root_path)
    end

    context 'if agent goes wrong' do
      let!(:agent) { create(:agent, password: "123456") }

      scenario '.sign_in as user and be signed in as agent' do
        click_link 'Se connecter'
        fill_in :user_email, with: agent.email
        fill_in :password, with: agent.password
        click_on "Se connecter"
        expect(current_path).to eq(agent.organisation_ids.first.home_path(agent.id))
      end
    end
  end

  def sign_up(user)
    fill_in :user_first_name, with: user.first_name
    fill_in :user_last_name, with: user.last_name
    fill_in :user_email, with: user.email
    fill_in :password, with: user.password
    click_on "Je m'inscris"
  end

  def expect_flash_info(message)
    expect(page).to have_selector('.alert.alert-info', text: message)
  end
end
