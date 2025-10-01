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

    click_on "Informations de l'organisation"
    click_on "Fermer MDS de Paris"

    expect(page).to have_content "L'organisation a été fermée."

    expect(new_organisation.reload.disabled_at).to be_present

    click_on "MDS de Paris"
    click_on "Réouvrir cette organisation"
    expect(page).to have_content "Organisation réouverte ! Vous pouvez inviter des agents à la rejoindre"

    expect(new_organisation.agents).to eq [agent]
    expect(new_organisation.reload.disabled_at).to be_nil
  end

  describe "fermer une organisation" do
    let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    context "quand des agents ont encore des rendez-vous à venir" do
      before do
        create(:rdv, agents: [other_agent], starts_at: 1.week.from_now, organisation:)
      end

      it "ne propose pas de supprimer l'organisation" do
        visit admin_organisation_path(organisation)
        expect(page).not_to have_content("Fermer #{organisation.name}")
      end
    end
  end
end
