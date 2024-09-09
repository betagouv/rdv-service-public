RSpec.describe CreneauxSearch::ForAgent, type: :service do
  let(:organisation) { create(:organisation) }
  let(:motif) { create :motif, organisation: organisation }

  describe "#next_availabilities" do
    let(:form) do
      instance_double(
        AgentCreneauxSearchForm,
        organisation: organisation,
        motif: motif,
        service: motif.service,
        agent_ids: [],
        team_ids: [],
        lieu_ids: [],
        date_range: Time.zone.today..(Time.zone.today + 6.days)
      )
    end
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    let(:lieu1) { create(:lieu, organisation: organisation, name: "MDS Valence") }
    let(:lieu2) { create(:lieu, organisation: organisation, name: "MDS Arquest") }

    before do
      create(:plage_ouverture, :weekly, agent: agent, motifs: [motif], lieu: lieu2, organisation: organisation, first_day: 2.weeks.from_now)
      create(:plage_ouverture, :weekly, agent: agent, motifs: [motif], lieu: lieu1, organisation: organisation, first_day: 1.week.from_now)
    end

    it "sorts the results by the date of the next availability" do
      availabilities = described_class.new(form).next_availabilities
      expect(availabilities.first.lieu).to eq lieu1
      expect(availabilities.last.lieu).to eq lieu2
    end
  end

  describe "lieux" do
    subject { described_class.new(form).lieux }

    let(:form) do
      instance_double(
        AgentCreneauxSearchForm,
        organisation: organisation,
        motif: motif,
        service: motif.service,
        agent_ids: agents.map(&:id),
        team_ids: teams.map(&:id),
        lieu_ids: lieux.map(&:id),
        date_range: Time.zone.today..(Time.zone.today + 6.days)
      )
    end

    let(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:lieu1) { create(:lieu, organisation: organisation) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekly, agent: agent1, motifs: [motif], lieu: lieu1, organisation: organisation) }

    let(:lieux) { [] }
    let(:agents) { [] }
    let(:teams) { [] }

    context "when there in only one plage" do
      context "when the lieu is unspecified" do
        let(:lieux) { [] }

        it { is_expected.to contain_exactly(lieu1) }
      end
    end

    context "when there are several plages for the motif" do
      let(:lieu2) { create(:lieu, organisation: organisation) }
      let(:agent2) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:plage_ouverture2) { create(:plage_ouverture, :weekly, agent: agent2, lieu: lieu2, motifs: [motif], organisation: organisation) }

      context "when the lieu is unspecified" do
        it { is_expected.to contain_exactly(lieu1, lieu2) }
      end

      context "when filtering by lieu" do
        let(:lieux) { [lieu2] }

        it { is_expected.to contain_exactly(lieu2) }
      end

      context "when filtering by agent" do
        let(:agents) { [agent2] }

        it { is_expected.to contain_exactly(lieu2) }
      end

      context "when filtering by agent and by lieu" do
        let(:agents) { [agent2] }
        let(:lieux) { [lieu1] }

        it { is_expected.to eq([]) }
      end
    end
  end

  describe "creneaux sans lieu" do
    before do
      travel_to(Time.zone.local(2022, 10, 15, 10, 0, 0))
    end

    let(:form) do
      instance_double(
        AgentCreneauxSearchForm,
        organisation: organisation,
        motif: motif,
        service: motif.service,
        agent_ids: [],
        team_ids: [],
        lieu_ids: nil,
        date_range: Date.new(2022, 10, 20)..Date.new(2022, 10, 30)
      )
    end
    let(:motif) { create :motif, :by_phone, organisation: organisation }
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], first_day: Date.new(2022, 10, 25), lieu: nil, organisation: organisation) }

    it "has results" do
      expect(described_class.new(form).build_result.creneaux).to be_any
    end

    describe "when there is concurrent PO with lieu" do
      let(:lieu) { create(:lieu, organisation: organisation) }
      let(:motif_with_lieu) { create :motif, organisation: organisation }
      let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif, motif_with_lieu], first_day: Date.new(2022, 10, 20), lieu: lieu, organisation: organisation) }

      it "give the good results with no conflict" do
        expect(described_class.new(form).build_result.creneaux.first.starts_at).to eq(Time.zone.local(2022, 10, 25, 8, 0, 0))
      end
    end
  end

  describe "#all_agents" do
    subject { described_class.new(form).all_agents }

    let(:form) do
      instance_double(
        AgentCreneauxSearchForm,
        organisation: organisation,
        motif: motif,
        service: motif.service,
        agent_ids: agents.map(&:id),
        team_ids: teams.map(&:id),
        lieu_ids: lieux.map(&:id),
        date_range: Time.zone.today..(Time.zone.today + 6.days)
      )
    end

    let(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:agent2) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:agent3) { create(:agent, basic_role_in_organisations: [organisation]) }

    let(:team1) { create(:team, agents: [agent1, agent2]) }

    let(:lieux) { [] }

    context "without agent or teams" do
      let(:agents) { [] }
      let(:teams) { [] }

      it { is_expected.to be_empty }
    end

    context "with an agent" do
      let(:agents) { [agent1] }
      let(:teams) { [] }

      it { is_expected.to contain_exactly(agent1) }
    end

    context "with a team" do
      let(:agents) { [] }
      let(:teams) { [team1] }

      it { is_expected.to contain_exactly(agent1, agent2) }
    end

    context "with agents and a team" do
      let(:agents) { [agent3] }
      let(:teams) { [team1] }

      it { is_expected.to contain_exactly(agent1, agent2, agent3) }
    end
  end
end
