# frozen_string_literal: true

describe "Migrating an agent from one organisation to another" do
  let(:super_admin) { create :super_admin }
  let!(:old_organisation) { create :organisation }
  let!(:new_organisation) { create :organisation, territory: old_organisation.territory }
  let(:agent) { create :agent, admin_role_in_organisations: [old_organisation] }

  let!(:motif1) { create :motif }
  let!(:motif2) { create :motif }
  let!(:rdv1) { create :rdv, organisation: old_organisation, agents: [agent], motif: motif1 }
  let!(:rdv2) { create :rdv, organisation: old_organisation, agents: [agent], motif: motif1 }
  let!(:rdv3) { create :rdv, organisation: old_organisation, agents: [agent], motif: motif2 }

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

    # RDVs are moved to new org
    expect(rdv1.reload.organisation).to eq(new_organisation)
    expect(rdv2.reload.organisation).to eq(new_organisation)
    expect(rdv3.reload.organisation).to eq(new_organisation)

    # Motifs a copied to new org
    expect(rdv1.motif).to have_attributes(motif1.attributes.except("id", "organisation_id", "created_at", "updated_at"))
    expect(rdv2.motif).to have_attributes(motif1.attributes.except("id", "organisation_id", "created_at", "updated_at"))
    expect(rdv3.motif).to have_attributes(motif2.attributes.except("id", "organisation_id", "created_at", "updated_at"))
    expect([rdv1.motif, rdv3.reload.motif]).to match_array(new_organisation.motifs)

    # RVS users are present in the new org
    expect(rdv1.users + rdv2.users + rdv3.users).to match_array(new_organisation.users)
  end

  context "when the agent has a rdv with another agent that is not being migrated" do
    let!(:shared_rdv) { create :rdv, organisation: old_organisation, agents: [agent, other_agent] }
    let(:other_agent) { create(:agent, admin_role_in_organisations: [old_organisation]) }

    it "doesn't migrate the records and shows an error" do
      click_button "Migrer"
      expect(agent.reload.organisations).to eq [old_organisation]
      expect(shared_rdv.reload.organisation).to eq old_organisation

      expect(page).to have_content("Cet agent a des RDVs avec d'autres agents de cette organisation, et ne peut donc pas être migré automatiquement.")
    end
  end

  context "when both organisations are in different territories" do
    let!(:new_organisation) { create :organisation, territory: create(:territory) }

    it "doesn't migrate the records and shows an error" do
      click_button "Migrer"
      expect(agent.reload.organisations).to eq [old_organisation]
      expect(rdv1.reload.organisation).to eq old_organisation
      expect(rdv2.reload.organisation).to eq old_organisation
      expect(rdv3.reload.organisation).to eq old_organisation

      expect(page).to have_content("vous ne pouvez donc pas migrer d'agent entre ces deux organisations")
    end
  end
end
