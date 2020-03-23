describe "Agent can CRUD absences" do
  let!(:agent) { create(:agent, :admin) }
  let!(:other_agent) { create(:agent, organisations: [agent.organisations.first]) }
  let!(:absence) { create(:absence, agent: agent) }
  let(:new_absence) { build(:absence) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Vos absences"
  end

  context 'for an agent' do
    scenario "default" do
      crud_absence(agent, agent)
    end
  end

  context 'for a secretaire' do
    let(:agent) { create(:agent, :secretaire) }

    scenario "cannot create absence" do
      expect_page_title("Vos absences")
      click_link 'Créer une pabsence', match: :first
      expect(page).to have_content("Aucun motif disponible. Vous ne pouvez pas créer de absence.")
    end

    context 'with motif for_secretariat' do
      let!(:motif) { create(:motif, :for_secretariat) }
      let(:absence) { create(:absence, agent: agent, motifs: [motif]) }

      scenario "can crud a absence" do
        crud_absence(agent, agent)
      end
    end
  end

  context 'for an other agent calendar' do
    let!(:absence) { create(:absence, agent: other_agent) }

    scenario "can crud a absence" do
      # select(other_agent.full_name, from: :id)
      visit organisation_agent_absences_path(agent.organisations.first.id, other_agent.id)
      crud_absence(agent, other_agent)
    end
  end

  def crud_absence(current_agent, agent_crud)
    title =  agent_crud == current_agent ? "Vos absences" : "absences de #{agent_crud.full_name_and_service}"

    expect_page_title(title)
    click_link absence.title

    expect_page_title("Modifier la absence")
    fill_in 'Description', with: 'La belle plage'
    click_button('Modifier')

    expect_page_title(title)
    click_link 'La belle plage'

    click_link('Supprimer')
    expect_page_title(title)
    empty_text = agent_crud == current_agent ? "Vous n'avez pas encore créé de absence" : "#{agent_crud.full_name} n'a pas encore créé de absence"
    expect_page_with_no_record_text(empty_text)

    click_link 'Créer une absence', match: :first

    expect_page_title("Nouvelle absence")
    fill_in 'Description', with: new_absence.title
    check absence.motifs.first.name
    click_button 'Créer'

    expect_page_title(title)
    click_link new_absence.title
  end
end
