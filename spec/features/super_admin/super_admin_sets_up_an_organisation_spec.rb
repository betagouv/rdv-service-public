describe "Super admin can configure an account" do
  let!(:super_admin_email) { create(:super_admin) }
  let(:organisation) { build(:organisation) }
  let(:agent) { build(:agent) }

  before do
    login_as(super_admin_email, scope: :super_admin)
    visit admin_agents_path
  end

  scenario "Create organisation and invite a agent" do
    click_link "Organisation"
    click_link "Création organisation"
    fill_in 'Nom', with: organisation.name
    fill_in 'Département', with: organisation.departement
    click_button 'Créer'
    click_link organisation.name

    click_link 'Agent'
    click_link 'Création agent'
    fill_in 'Email', with: agent.email
    fill_in 'Prénom', with: agent.first_name
    fill_in 'Nom', with: agent.last_name
    select organisation.name, from: 'Organisation'
    click_button 'Créer'
    click_link agent.email
    click_link 'Inviter'
    click_link 'Se déconnecter'

    open_email(agent.email)
    expect(current_email.subject).to eq I18n.t("devise.mailer.invitation_instructions.subject")
  end
end
