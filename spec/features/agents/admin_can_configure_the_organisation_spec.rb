describe "Admin can configure the organisation" do
  let!(:pmi) { create(:service, name: 'PMI') }
  let!(:service_social) { create(:service, name: 'Service social') }
  let!(:agent_admin) { create(:agent, :admin, service: pmi) }
  let!(:agent_user) { create(:agent) }
  let!(:motif_libelle) { create(:motif_libelle, name: "Motif 1") }
  let!(:motif_libelle2) { create(:motif_libelle, name: "Motif 2") }
  let!(:motif_libelle3) { create(:motif_libelle, name: "Motif 3", service: service_social) }
  let!(:motif) { create(:motif, name: "Motif 1") }
  let!(:user) { create(:user) }
  let!(:lieu) { create(:lieu) }
  let!(:secretariat) { create(:service, :secretariat) }
  let(:le_nouveau_lieu) { build(:lieu) }
  let(:le_nouveau_motif) { build(:motif, name: "Motif 2") }
  let(:la_nouvelle_org) { build(:organisation) }

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
    click_button 'Créer'
    expect_page_title("Vos lieux de consultation")
    click_link le_nouveau_lieu.name
  end

  scenario "CRUD on agents" do
    click_link "Vos agents"
    expect_page_title("Vos agents")

    click_link agent_user.full_name
    expect_page_title("Modifier le professionnel")
    choose :agent_permission_role_admin
    click_button('Modifier')

    expect_page_title("Vos agents")
    expect(page).to have_selector('span.badge.badge-danger', count: 2)

    click_link agent_user.full_name
    click_link('Supprimer')

    expect_page_title("Vos agents")
    expect(page).to have_no_content(agent_user.full_name)

    click_link 'Inviter un professionnel', match: :first
    fill_in 'Email', with: 'jean@paul.com'
    click_button 'Envoyer une invitation'

    expect_page_title("Vos agents")
    expect(page).to have_content('jean@paul.com')

    open_email('jean@paul.com')
    expect(current_email.subject).to eq I18n.t("devise.mailer.invitation_instructions.subject")
  end

  scenario "Update organisation" do
    click_link "Votre organisation"
    expect_page_title("Votre organisation")
    expect(page).to have_content('Statistiques')
    expect(page).to have_content('RDV créés')
    expect(page).to have_content('Usagers créés')

    click_link 'Modifier'
    fill_in 'Nom', with: la_nouvelle_org.name
    fill_in 'Téléphone', with: la_nouvelle_org.phone_number
    fill_in 'Horaires', with: la_nouvelle_org.horaires
    click_button 'Modifier'

    expect(page).to have_content('L\'organisation a été modifiée.')
  end

  scenario "CRUD on motifs", js: true do
    click_link "Vos motifs"
    expect_page_title("Vos motifs")

    click_link motif.name
    expect(page).to have_content(motif.name)
    click_link 'Modifier'

    expect(page).to have_content("Modifier le motif")
    expect(page.find_by_id('motif_name')).to have_content(motif.name)
    select(motif_libelle2.name, from: :motif_name)
    page.execute_script "$('.slimscroll-menu').scrollTop(10000)"
    click_button('Modifier')
    expect(page).to have_content(motif_libelle2.name)
    expect_page_title("Vos motifs")

    click_link le_nouveau_motif.name
    expect(page).to have_content(le_nouveau_motif.name)
    click_link('Supprimer')
    begin
      page.driver.browser.switch_to.alert.accept
    rescue Selenium::WebDriver::Error::NoSuchAlertError
      click_link('Supprimer')
      retry
    end

    expect_page_title("Vos motifs")
    expect_page_with_no_record_text("Vous n'avez pas encore créé de motif.")

    click_link 'Créer un motif', match: :first
    expect(page).to have_content("Nouveau motif")
    ## Check secretariat is unavailable
    expect(page.all('select#motif_service_id option').map(&:value)).to match_array ["", pmi.id.to_s, service_social.id.to_s]
    select(service_social.name, from: :motif_service_id)
    expect(page).to have_select('motif[name]', with_options: ['', motif_libelle3.name], wait: 10)
    select(motif_libelle3.name, from: :motif_name)
    fill_in 'Couleur', with: le_nouveau_motif.color
    click_button 'Créer'
    expect(page).to have_link(motif_libelle3.name)
  end
end
