RSpec.describe "Gestion des organisations depuis les paramètres d'espace" do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory:, name: "MDS de Pantin") }
  let(:agent) do
    create(:agent, role_in_territories: [territory], admin_role_in_organisations: [organisation])
  end

  before do
    login_as(agent, scope: :agent)
  end

  specify "full lifecycle" do
    visit admin_territory_path(id: territory.id)
    click_on "Organisations"

    click_on "Ajouter une organisation"

    fill_in "Nom de votre organisation", with: "MDS de Paris"
    click_on "Enregistrer"

    new_organisation = Organisation.find_by(name: "MDS de Paris")

    expect(new_organisation).to have_attributes(territory:, agents: [agent])

    visit admin_territory_organisations_path(territory_id: territory.id)
    click_on "Fermer une organisation"

    select "MDS de Paris", from: :organisation_id

    click_on "Fermer cette organisation"

    expect(page).to have_content("L'organisation a été fermée.")

    expect(new_organisation.reload.agents).to be_empty

    click_on "MDS de Paris"
    click_on "Réouvrir cette organisation"

    expect(new_organisation.agents).to eq [agent]
  end

  describe "fermer une organisation" do
    let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    context "quand des agents ont encore des rendez-vous à venir" do
      before do
        create(:rdv, agents: [other_agent], starts_at: 1.week.from_now, organisation:)
      end

      it "ne propose pas de supprimer l'organisation" do
        visit select_for_close_admin_territory_organisations_path(territory_id: territory.id)
        expect(page).not_to have_content(organisation.name)
      end
    end

    context "quand une race condition fait qu'on essaye quand même de supprimer l'organisation" do
      let!(:agent_without_rdv) { create(:agent, basic_role_in_organisations: [organisation]) }

      it "garde l'agent courant dans l'organisation, et supprime les agents qui peuvent l'être" do
        visit select_for_close_admin_territory_organisations_path(territory_id: territory.id)
        create(:rdv, agents: [other_agent], starts_at: 1.week.from_now, organisation:)
        click_on "Fermer cette organisation"

        expect(page).to have_content("L'organisation n'a pas pu être fermée parce que des agents on encore des rendez-vous à venir dans cette organisation.")

        expect(organisation.reload.agents).to contain_exactly(agent, other_agent)
      end
    end
  end
end
