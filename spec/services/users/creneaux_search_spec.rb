# frozen_string_literal: true

describe Users::CreneauxSearch, type: :service do
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let(:date_range) { (Date.parse("2020-10-20")..Date.parse("2020-10-23")) }
  let(:now) { Time.zone.parse("2020-10-19 15:34") }

  before do
    travel_to(now)
  end

  it "call builder without special options" do
    user = create(:user)
    motif = create(:motif, name: "Coucou", organisation: organisation, location_type: :public_office)
    expect(SlotBuilder).to receive(:available_slots).with(motif, lieu, date_range, [])
    described_class.new(user: user, motif: motif, lieu: lieu, date_range: date_range).creneaux
  end

  it "call with referent as filter when follow_up motif" do
    motif = create(:motif, follow_up: true, organisation: organisation)
    agent = create(:agent, basic_role_in_organisations: [organisation])
    user = create(:user, organisations: [organisation], agents: [agent])
    expect(SlotBuilder).to receive(:available_slots).with(motif, lieu, date_range, [agent])
    described_class.new(user: user, motif: motif, lieu: lieu, date_range: date_range).creneaux
  end

  it "call without referents when user without referents" do
    motif = create(:motif, follow_up: true, organisation: organisation)
    user = create(:user, agents: [])
    expect(SlotBuilder).to receive(:available_slots).with(motif, lieu, date_range, [])
    described_class.new(user: user, motif: motif, lieu: lieu, date_range: date_range).creneaux
  end

  context "with geo search" do
    let(:user) { create(:user) }

    context "with agent sectorisation" do
      it "calls without agents filter" do
        mock_geo_search = instance_double(Users::GeoSearch, attributed_agents_by_organisation: {})
        motif = create(:motif, :sectorisation_level_agent, organisation: organisation)
        expect(SlotBuilder).to receive(:available_slots).with(motif, lieu, date_range, [])
        described_class.new(user: user, motif: motif, lieu: lieu, date_range: date_range, geo_search: mock_geo_search).creneaux
      end

      it "calls without agents filter when no attributed agents" do
        mock_geo_search = instance_double(Users::GeoSearch, attributed_agents_by_organisation: { organisation => Agent.none })
        motif = create(:motif, organisation: organisation)
        expect(SlotBuilder).to receive(:available_slots).with(motif, lieu, date_range, [])
        described_class.new(user: user, motif: motif, lieu: lieu, date_range: date_range, geo_search: mock_geo_search).creneaux
      end

      context "when the lieu is nil" do
        let(:lieu) { nil }
        let(:motif) { create(:motif, :sectorisation_level_agent, organisation: organisation) }

        it "doesn't crash" do
          expect do
            mock_geo_search = instance_double(Users::GeoSearch, attributed_agents_by_organisation: { organisation => Agent.none })
            described_class.new(user: user, motif: motif, lieu: lieu, date_range: date_range, geo_search: mock_geo_search).creneaux
          end.not_to raise_error
        end
      end
    end

    it "some attributed agents" do
      agent1 = create(:agent, basic_role_in_organisations: [organisation])
      agent2 = create(:agent, basic_role_in_organisations: [organisation])
      motif = create(:motif, :sectorisation_level_agent, organisation: organisation)
      mock_geo_search = instance_double(Users::GeoSearch, attributed_agents_by_organisation: { organisation => Agent.where(id: [agent1.id, agent2.id]) })
      expect(SlotBuilder).to receive(:available_slots).with(motif, lieu, date_range, match_array([agent1, agent2]))
      described_class.new(user: user, motif: motif, lieu: lieu, date_range: date_range, geo_search: mock_geo_search).creneaux
    end
  end
end
