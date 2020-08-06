describe Creneau::AgentSearch, type: :model do
  let!(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, organisations: [organisation]) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let(:plage_ouverture) { create(:plage_ouverture, :weekly, agent: agent, lieu: lieu, organisation: organisation) }
  let(:lieu_ids) { [] }
  let(:agent_ids) { [] }
  let(:agent_search) { Creneau::AgentSearch.new(organisation_id: organisation.id, motif_id: motif.id, agent_ids: agent_ids, lieu_ids: lieu_ids) }

  describe "#lieux" do
    subject { agent_search.lieux }

    let(:motif) { plage_ouverture.motifs.first }

    it { expect(subject).to contain_exactly(lieu) }

    context "when there is many agents / po / lieux but same motif" do
      let(:lieu2) { create(:lieu, organisation: organisation) }
      let(:agent2) { create(:agent, organisations: [organisation]) }
      let!(:plage_ouverture2) { create(:plage_ouverture, :weekly, agent: agent2, lieu: lieu2, motifs: [motif], organisation: organisation) }

      it { expect(subject).to contain_exactly(lieu, lieu2) }

      context "when filtering by lieu" do
        let(:lieu_ids) { [lieu2.id] }

        it { expect(subject).to contain_exactly(lieu2) }
      end

      context "when filtering by agent" do
        let(:agent_ids) { [agent2.id] }

        it { expect(subject).to contain_exactly(lieu2) }

        context "and by lieu" do
          let(:lieu_ids) { [lieu.id] }

          it { expect(subject).to eq([]) }
        end
      end
    end
  end
end
