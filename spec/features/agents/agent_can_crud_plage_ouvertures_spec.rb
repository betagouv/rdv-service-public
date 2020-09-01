describe "Agent can CRUD plage d'ouverture" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:motif) { create(:motif, name: "Suivi bonjour", service: service, organisation: organisation) }
  let!(:agent) { create(:agent, :admin, service: service, organisations: [organisation]) }
  let!(:other_agent) { create(:agent, service: service, organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, agent: agent, organisation: organisation) }
  let(:new_plage_ouverture) { build(:plage_ouverture, lieu: lieu, agent: agent, organisation: organisation) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Plages d'ouverture"
  end

  context "for an agent" do
    scenario "default" do
      crud_plage_ouverture(agent, agent)
    end
  end

  context "for a secretaire" do
    let(:agent) { create(:agent, :secretaire, organisations: [organisation]) }

    scenario "cannot create plage_ouverture" do
      expect_page_title("Vos plages d'ouverture")
      click_link "Créer une plage d'ouverture", match: :first
      expect(page).to have_content("Aucun motif disponible. Vous ne pouvez pas créer de plage d'ouverture.")
    end

    context "with motif for_secretariat" do
      let!(:motif) { create(:motif, :for_secretariat, name: "Suivi bonjour", service: service, organisation: organisation) }
      let(:plage_ouverture) { create(:plage_ouverture, lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

      scenario "can crud a plage_ouverture" do
        crud_plage_ouverture(agent, agent)
      end
    end
  end

  context "for an other agent calendar" do
    let!(:plage_ouverture) { create(:plage_ouverture, lieu: lieu, agent: other_agent, organisation: organisation) }

    scenario "can crud a plage_ouverture" do
      # select(other_agent.full_name, from: :id)
      visit admin_organisation_agent_plage_ouvertures_path(organisation, other_agent.id)
      crud_plage_ouverture(agent, other_agent)
    end
  end

  def crud_plage_ouverture(current_agent, agent_crud)
    title =  agent_crud == current_agent ? "Vos plages d'ouverture" : "Plages d'ouverture de #{agent_crud.full_name_and_service}"

    expect_page_title(title)
    click_link plage_ouverture.title

    expect_page_title("Modifier la plage d'ouverture")
    fill_in "Description", with: "La belle plage"
    click_button("Modifier")

    expect_page_title("Modifier la plage d'ouverture")
    expect(page).to have_content("La belle plage")

    click_link("Supprimer")
    expect_page_title(title)
    empty_text = agent_crud == current_agent ? "Vous n'avez pas encore créé de plage d'ouverture" : "#{agent_crud.full_name} n'a pas encore créé de plage d'ouverture"
    expect_page_with_no_record_text(empty_text)

    click_link "Créer une plage d'ouverture", match: :first

    expect_page_title("Nouvelle plage d'ouverture")
    fill_in "Description", with: new_plage_ouverture.title
    check "Suivi bonjour"
    click_button "Créer"

    expect_page_title(title)
    click_link new_plage_ouverture.title
  end
end
