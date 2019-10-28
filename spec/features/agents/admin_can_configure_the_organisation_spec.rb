describe "Admin can configure the organisation" do
  let!(:pmi) { create(:service, name: 'PMI')}
  let!(:agent_admin) { create(:agent, :admin, service: pmi) }
  let!(:agent_user) { create(:agent) }
  let!(:motif) { create(:motif) }
  let!(:user) { create(:user) }
  let!(:lieu) { create(:lieu) }
  let!(:secretariat) { create(:service, :secretariat)}
  let(:le_nouveau_lieu) { build(:lieu) }
  let(:le_nouveau_motif) { build(:motif) }

  before do
    login_as(agent_admin, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Paramètres"
  end

  scenario "CRUD on lieux" do
    click_link "Vos lieux"
    expect_page_title("Vos lieux de consultation")

    click_link lieu.name
    expect_page_title("Modifier le lieu")
    fill_in 'Nom', with: 'Le nouveau lieu'
    click_button('Modifier')

    expect_page_title("Vos lieux de consultation")
    click_link 'Le nouveau lieu'

    click_link('Supprimer')

    expect_page_title("Vos lieux de consultation")
    expect_page_with_no_record_text("Vous n'avez pas encore ajouté de lieu de consultation.")

    click_link 'Ajouter un lieu', match: :first

    expect_page_title("Nouveau lieu")
    fill_in 'Nom', with: le_nouveau_lieu.name
    fill_in 'Adresse', with: le_nouveau_lieu.address
    fill_in 'Téléphone', with: le_nouveau_lieu.telephone
    fill_in 'Horaires', with: le_nouveau_lieu.horaires
    click_button 'Créer'
    expect_page_title("Vos lieux de consultation")
    click_link le_nouveau_lieu.name
  end

  scenario "CRUD on agents" do
    click_link "Vos professionnels"
    expect_page_title("Vos professionnels")

    click_link agent_user.full_name
    expect_page_title("Modifier le professionnel")
    choose :agent_permission_role_admin
    click_button('Modifier')

    expect_page_title("Vos professionnels")
    expect(page).to have_selector('span.badge.badge-danger', count: 2)

    click_link agent_user.full_name
    click_link('Supprimer')

    expect_page_title("Vos professionnels")
    expect(page).to have_no_content(agent_user.full_name)

    click_link 'Inviter un professionnel', match: :first
    fill_in 'Email', with: 'jean@paul.com'
    click_button 'Envoyer une invitation'

    expect_page_title("Vos professionnels")
    expect(page).to have_content('jean@paul.com')

    open_email('jean@paul.com')
    expect(current_email.subject).to eq I18n.t("devise.mailer.invitation_instructions.subject")
  end

  scenario "CRUD on motifs" do
    click_link "Vos motifs"
    expect_page_title("Vos motifs")

    click_link motif.name
    expect_page_title("Modifier le motif")
    fill_in :motif_name, with: 'Le nouveau motif'
    click_button('Modifier')

    expect_page_title("Vos motifs")
    click_link 'Le nouveau motif'

    click_link('Supprimer')
    expect_page_title("Vos motifs")
    expect_page_with_no_record_text("Vous n'avez pas encore créé de motif.")

    click_link 'Créer un motif', match: :first
    expect_page_title("Nouveau motif")
    fill_in 'Nom', with: le_nouveau_motif.name
    
    ## Check secretariat is unavailable
    page.all('select#motif_service_id option').map(&:value).should match_array ["", "#{pmi.id}"]
    select(agent_admin.service.name, from: :motif_service_id)
    fill_in 'Couleur', with: le_nouveau_motif.color
    click_button 'Créer'

    expect_page_title("Vos motifs")
    click_link le_nouveau_motif.name
  end
end
