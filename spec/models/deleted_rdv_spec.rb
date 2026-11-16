RSpec.describe DeletedRdv do
  describe "création à la suppression d'un RDV" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:user) { create(:user) }
    let!(:rdv) { create(:rdv, organisation: organisation, agents: [agent], users: [user], created_by: agent) }

    it "copie les informations du RDV" do
      expect { rdv.destroy! }.to change(described_class, :count).by(1)

      deleted_rdv = described_class.last
      expect(deleted_rdv).to have_attributes(
        id: rdv.id,
        starts_at: rdv.starts_at,
        ends_at: rdv.ends_at,
        organisation_id: organisation.id,
        motif_id: rdv.motif_id,
        motif_name: rdv.motif.name,
        lieu_id: rdv.lieu_id,
        status: "unknown",
        created_by_type: "Agent",
        created_by_id: agent.id,
        created_by_name: agent.full_name,
        user_ids: [user.id],
        agent_ids: [agent.id]
      )
    end

    it "ne crée rien si la suppression échoue" do
      allow_any_instance_of(AgentsRdv).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid) # rubocop:disable RSpec/AnyInstance
      expect { rdv.destroy }.to raise_error(ActiveRecord::StatementInvalid)
      expect(described_class.count).to eq(0)
    end

    it "conserve les données même si les références sont supprimées" do
      rdv.destroy!
      expect { Lieu.where(id: rdv.lieu_id).delete_all }.not_to raise_error
      expect(described_class.last.user_ids).to eq([user.id])
    end
  end
end
