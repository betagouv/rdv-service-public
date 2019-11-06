describe Agent, type: :model do
  describe '#soft_delete' do
    before { agent.soft_delete deleted_org }
    context 'with many remaining organisations' do
      let(:agent) { create(:agent, :with_multiple_organisations) }
      let(:deleted_org) { agent.organisations.first }
      it { expect(agent.organisation_ids).not_to include(deleted_org.id) }
      it { expect(agent.deleted_at).to be_nil }
    end
    context 'with one remaining organisations' do
      let(:agent) { create(:agent) }
      let(:deleted_org) { agent.organisations.first }
      it { expect(agent.organisation_ids).to eq [deleted_org.id] }
      it { expect(agent.deleted_at).not_to be_nil }
    end
    context 'with no organisation given' do
      let(:agent) { create(:agent, :with_multiple_organisations) }
      let(:deleted_org) { nil }
      it { expect(agent.deleted_at).not_to be_nil }
    end
  end
end
