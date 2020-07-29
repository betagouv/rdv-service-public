describe "Super admin can configure an account" do
  let!(:super_admin) { create(:super_admin) }
  let(:organisation) { build(:organisation) }
  let(:agent) { build(:agent) }
  let!(:agent_1) { create(:agent) }

  before do
    login_as(super_admin, scope: :super_admin)
    visit admin_agents_path
  end

  scenario "Create organisation and invite a agent" do
    click_link "Organisation"
    click_link "Création organisation"
    fill_in "Nom", with: organisation.name
    fill_in "Département", with: organisation.departement
    click_button "Créer"
    click_link organisation.name

    click_link "Agent"
    click_link "Création agent"
    fill_in "Email", with: agent.email
    fill_in "Prénom", with: agent.first_name
    fill_in "Nom", with: agent.last_name
    select organisation.name, from: "Organisation"
    select Service.first.name, from: "Service"
    click_button "Créer"
    click_link agent.email
    click_link "Inviter"
    click_link "Se déconnecter"

    open_email(agent.email)
    expect(current_email.subject).to eq I18n.t("devise.mailer.invitation_instructions.subject")
  end

  shared_examples "an administrate resource" do
    it do
      class_name = resource.class.model_name.human
      click_link class_name
      expect_page_title(class_name)

      click_link resource.id.to_s
      expect_page_title("Détails #{resource.class.model_name} ##{resource.id}")

      click_link class_name
      click_link "Création #{resource.class.name.titleize.downcase}"
      expect_page_title("Création #{class_name.titleize}")

      click_link "Précédent"
      expect_page_title(class_name)
    end
  end

  [:agent, :user, :super_admin, :lieu, :service, :motif, :rdv, :plage_ouverture, :absence, :motif_libelle].each do |resource|
    context resource do
      let!(:resource) { create resource }
      it_behaves_like "an administrate resource"
    end
  end

  def expect_page_title(expected_title)
    expect(page).to have_selector("h1.main-content__page-title", text: expected_title)
  end
end
