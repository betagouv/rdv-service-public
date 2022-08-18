# frozen_string_literal: true

describe "Migrating an agent from one organisation to another" do
  let(:super_admin) { create :super_admin }
  let!(:old_organisation) { create :organisation }
  let!(:new_organisation) { create :organisation, territory: old_organisation.territory }
  let(:motif) { create :motif }
  let(:agent) { create :agent, service: motif.service, admin_role_in_organisations: [old_organisation] }

  let!(:rdv) { create :rdv, motif: motif, organisation: old_organisation, agents: [agent] }

  before do
    login_as(super_admin, scope: :super_admin)
    visit super_admins_agent_path(agent)
    click_link "Migrer"
    fill_in("ID de la nouvelle organisation", with: new_organisation.id)
  end

  it "moves the relevant records from one organisation to the next" do
    click_button "Migrer"

    expect(page).to have_content "#{agent.full_name} et toutes ses données de #{old_organisation.name} ont été migrés vers #{new_organisation.name}"

    expect(agent.reload.organisations).to eq [new_organisation]

    expect(rdv.reload.organisation).to eq new_organisation
    expect([rdv.motif]).to eq new_organisation.motifs
    expect(rdv.users).to eq new_organisation.users
  end

  context "when the agent has a rdv with another agent that is not being migrated" do
    let!(:rdv) { create :rdv, motif: motif, organisation: old_organisation, agents: [agent, other_agent] }
    let(:other_agent) { create(:agent, service: motif.service, admin_role_in_organisations: [old_organisation]) }

    it "doesn't migrate the records and shows an error" do
      click_button "Migrer"
      expect(agent.reload.organisations).to eq [old_organisation]
      expect(rdv.reload.organisation).to eq old_organisation

      expect(page).to have_content("Cet agent a des RDVs avec d'autres agents de cette organisation, et ne peut donc pas être migré automatiquement.")
    end
  end

  context "when both organisations are in different territories" do
    let!(:new_organisation) { create :organisation, territory: create(:territory) }

    it "doesn't migrate the records and shows an error" do
      click_button "Migrer"
      expect(agent.reload.organisations).to eq [old_organisation]
      expect(rdv.reload.organisation).to eq old_organisation

      expect(page).to have_content("vous ne pouvez donc pas migrer d'agent entre ces deux organisations")
    end
  end
end
