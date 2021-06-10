# frozen_string_literal: true

describe SearchCreneauxForAgentsService, type: :service do
  subject { described_class.perform_with(agent_creneaux_search_form) }

  let!(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let(:plage_ouverture) { create(:plage_ouverture, :weekly, agent: agent, lieu: lieu, organisation: organisation) }
  let(:motif) { plage_ouverture.motifs.first }
  let(:lieu_ids) { [] }
  let(:agent_ids) { [] }
  let(:agent_creneaux_search_form) do
    instance_double(
      AgentCreneauxSearchForm,
      organisation: organisation,
      motif: motif,
      service: motif.service,
      agent_ids: agent_ids,
      lieu_ids: lieu_ids,
      date_range: Time.zone.today..(Time.zone.today + 6.days)
    )
  end

  it { expect(subject.map(&:lieu)).to contain_exactly(lieu) }

  context "when there are multiple agents and plage ouvertures and lieux" do
    let!(:lieu2) { create(:lieu, organisation: organisation) }
    let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:plage_ouverture2) { create(:plage_ouverture, :weekly, agent: agent2, lieu: lieu2, motifs: [motif], organisation: organisation) }

    it { expect(subject.map(&:lieu)).to contain_exactly(lieu, lieu2) }

    context "when filtering by lieu" do
      let(:lieu_ids) { [lieu2.id] }

      it { expect(subject.map(&:lieu)).to contain_exactly(lieu2) }
    end

    context "when filtering by agent" do
      let(:agent_ids) { [agent2.id] }

      it { expect(subject.map(&:lieu)).to contain_exactly(lieu2) }

      context "and by lieu" do
        let(:lieu_ids) { [lieu.id] }

        it { expect(subject).to eq([]) }
      end
    end
  end
end
