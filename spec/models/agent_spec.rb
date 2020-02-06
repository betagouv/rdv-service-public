describe Agent, type: :model do
  describe '#soft_delete' do
    context 'with many remaining organisations' do
      before { agent.soft_delete deleted_org }
      let(:agent) { create(:agent, :with_multiple_organisations) }
      let(:deleted_org) { agent.organisations.first }
      it { expect(agent.organisation_ids).not_to include(deleted_org.id) }
      it { expect(agent.deleted_at).to be_nil }
    end

    context 'with one remaining organisations' do
      let!(:agent) { create(:agent) }
      let(:deleted_org) { agent.organisations.first }

      context 'without rdv' do
        it { expect { agent.soft_delete deleted_org }.to change(Agent, :count).by(-1) }
      end

      context 'with rdv' do
        let!(:rdv) { create(:rdv, agent_ids: [agent.id]) }
        before { agent.soft_delete deleted_org }

        it { expect(agent.deleted_at).not_to be_nil }
      end
    end

    context 'with no organisation given' do
      let!(:agent) { create(:agent, :with_multiple_organisations) }
      let(:deleted_org) { nil }

      it { expect { agent.soft_delete deleted_org }.to change(Agent, :count).by(-1) }
    end
  end
end
