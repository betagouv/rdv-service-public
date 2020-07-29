describe 'Agent can create user' do
  let!(:organisation) { create(:organisation, name: 'MDS des Champs') }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: 'Jean', last_name: 'LEGENDE', email: 'jean@legende.com', organisations: [organisation])
  end

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link 'Vos usagers'
    click_link 'Créer un usager', match: :first
    expect_page_title('Nouvel usager')
  end

  it 'should work' do
    fill_in :user_first_name, with: 'Marco'
    fill_in :user_last_name, with: 'Lebreton'
    click_button 'Créer'
    expect_page_title('Marco LEBRETON')
    expect(page).to have_no_content('Inviter')
    click_link 'Modifier'
    fill_in 'Email', with: 'marco@lebreton.bzh'
    click_button 'Modifier'
    click_link 'Inviter'
    open_email('marco@lebreton.bzh')
    expect(current_email.subject).to eq I18n.t('devise.mailer.invitation_instructions.subject')
  end

  context 'user already exists in other organisation' do
    let!(:existing_user) do
      create(:user, first_name: 'Cee-Lo', last_name: 'GREEN', email: 'ceelo@green.com', organisations: [create(:organisation)])
    end

    it 'should allow using existing user' do
      fill_in :user_first_name, with: 'Cee-Lo'
      fill_in :user_last_name, with: 'Green'
      fill_in :user_email, with: 'ceelo@green.com'
      click_button 'Créer'
      expect(page).to have_content('Un usager a été trouvé pour cet email')
      expect(page).to have_content('Usager trouvé')
      click_link "Associer cet usager à l'organisation MDS des Champs"
      expect_page_title('Cee-Lo GREEN')
      expect(page).to have_content("L'usager a été associé à votre organisation.")
      expect(existing_user.reload.organisations).to include(organisation)
    end
  end
end
