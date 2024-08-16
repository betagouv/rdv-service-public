RSpec.describe Users::CreneauxSearch, type: :service do
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
    user = create(:user, organisations: [organisation], referent_agents: [agent])
    expect(SlotBuilder).to receive(:available_slots).with(motif, lieu, date_range, [agent])
    described_class.new(user: user, motif: motif, lieu: lieu, date_range: date_range).creneaux
  end

  it "call without referents when user without referents" do
    motif = create(:motif, follow_up: true, organisation: organisation)
    user = create(:user, referent_agents: [])
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

  context "for a collectif motif" do
    subject { described_class.new(user: user, motif: motif, lieu: lieu) }

    let!(:motif) { create(:motif, collectif: true) }
    let!(:rdv) { create(:rdv, :future, motif: motif, lieu: lieu, starts_at: 3.days.from_now) }
    let!(:passed_rdv) { create(:rdv, motif: motif, lieu: lieu, starts_at: 2.days.ago) }
    let!(:rdv_with_user) { create(:rdv, :future, motif: motif, lieu: lieu, users: [user], starts_at: 4.days.from_now) }
    let!(:rdv_in_different_lieu) { create(:rdv, :future, motif: motif, lieu: create(:lieu)) }
    let!(:rdv_with_no_remaining_seat) { create(:rdv, :future, motif: motif, lieu: lieu, max_participants_count: 1) }
    let!(:rdv_after_max_public_booking_delay) { create(:rdv, :future, motif: motif, lieu: lieu, starts_at: motif.end_booking_delay + 1.hour) }
    let!(:rdv_before_min_public_booking_delay) { create(:rdv, :future, motif: motif, lieu: lieu, starts_at: motif.start_booking_delay - 1.hour) }
    let!(:user) { create(:user) }

    it "returns the subscribable collective rdvs (rdv and rdv_with_user)" do
      expect(subject.next_availability).to eq(rdv)
      expect(subject.creneaux).to match_array([rdv, rdv_with_user])
    end

    context "when there are geo attributed agents" do
      subject { described_class.new(user: user, motif: motif, lieu: lieu, geo_search: geo_search) }

      let!(:agent) { create(:agent) }
      let!(:motif) { create(:motif, collectif: true, organisation: organisation, sectorisation_level: "agent") }
      let!(:rdv) { create(:rdv, :future, motif: motif, lieu: lieu, agents: [agent]) }
      let!(:rdv2) { create(:rdv, :future, motif: motif, lieu: lieu, agents: [build(:agent)]) }
      let!(:geo_search) { instance_double(Users::GeoSearch, attributed_agents_by_organisation: { organisation => [agent] }) }

      it "returns the rdv linked to the geo attributed agents" do
        expect(subject.next_availability).to eq(rdv)
        expect(subject.creneaux).to match_array([rdv])
      end
    end

    context "when it is a follow up motif" do
      subject { described_class.new(user: user, motif: motif, lieu: lieu) }

      let!(:agent) { create(:agent) }
      let!(:user) { create(:user, referent_agents: [agent]) }
      let!(:motif) { create(:motif, collectif: true, organisation: organisation, follow_up: true) }
      let!(:rdv) { create(:rdv, :future, motif: motif, lieu: lieu, agents: [agent]) }
      let!(:rdv2) { create(:rdv, :future, motif: motif, lieu: lieu, agents: [build(:agent)]) }

      it "returns the rdv linked to referents" do
        expect(subject.next_availability).to eq(rdv)
        expect(subject.creneaux).to match_array([rdv])
      end
    end
  end

  describe ".creneau_for" do
    subject do
      described_class.creneau_for(
        user: user,
        motif: motif,
        lieu: lieu,
        starts_at: starts_at
      )
    end

    let(:user) { create(:user) }
    let(:motif) { create(:motif, name: "Coucou", location_type: :home, organisation: organisation) }
    let(:starts_at) { Time.zone.parse("2020-10-20 09:30") }
    let(:now) { Time.zone.parse("2020-10-19 14:30") }

    before do
      travel_to(now)
      allow(SlotBuilder).to receive(:available_slots).and_return(mock_creneaux)
    end

    context "some matching creneaux" do
      let(:mock_creneaux) do
        [
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 09:30")),
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 10:00")),
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 10:30")),
        ]
      end

      it { is_expected.to eq(mock_creneaux[0]) }
    end

    context "no matching creneaux" do
      let(:mock_creneaux) do
        [
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 10:00")),
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 10:30")),
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 11:30")),
        ]
      end

      it { is_expected.to be_nil }
    end

    context "no creneaux built at all" do
      let(:mock_creneaux) { [] }

      it { is_expected.to be_nil }
    end
  end
end
