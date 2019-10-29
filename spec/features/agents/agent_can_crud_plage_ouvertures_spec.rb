describe "Agent can CRUD users" do
  let(:agent) { create(:agent) }
  let(:secretaire) { create(:agent, :secretaire)}
  let!(:plage_ouverture) { create(:plage_ouverture, agent: agent)}
  let(:new_plage_ouverture) { build(:plage_ouverture)}

  context 'for an agent' do
    before do
      login_as(agent, scope: :agent)
      visit authenticated_agent_root_path
      click_link "Vos plages d'ouverture"
    end

    scenario "default" do
      expect_page_title("Vos plages d'ouverture")
      click_link plage_ouverture.title

      expect_page_title("Modifier la plage d'ouverture")
      fill_in 'Nom', with: 'La belle plage'
      click_button('Modifier')

      expect_page_title("Vos plages d'ouverture")
      click_link 'La belle plage'

      click_link('Supprimer')
      expect_page_title("Vos plages d'ouverture")
      expect_page_with_no_record_text("Vous n'avez pas encore créé de plage d'ouverture")

      click_link 'Créer une plage d\'ouverture', match: :first

      expect_page_title("Nouvelle plage d'ouverture")
      fill_in 'Nom', with: new_plage_ouverture.title
      check agent.service.motifs.first.name
      click_button 'Créer'

      expect_page_title("Vos plages d'ouverture")
      click_link new_plage_ouverture.title
    end
  end

  context 'for a secretaire' do
    before do
      login_as(secretaire, scope: :agent)
      visit authenticated_agent_root_path
      click_link "Vos plages d'ouverture"
    end
    scenario "cannot create plage_ouverture" do
      expect_page_title("Vos plages d'ouverture")
      click_link 'Créer une plage d\'ouverture', match: :first
      expect(page).to have_content("Aucun motif disponible. Vous ne pouvez pas créer de plage d'ouverture.")
    end
    context 'with one by_phone motif' do 
      let!(:motif) { create(:motif, :by_phone) }
      scenario "can create a plage_ouverture" do
        click_link 'Créer une plage d\'ouverture', match: :first
        fill_in 'Nom', with: new_plage_ouverture.title
        check motif.name
        click_button 'Créer'

        expect_page_title("Vos plages d'ouverture")
        click_link new_plage_ouverture.title
      end
    end
  end

end
