describe Creneau, type: :model do
  let(:organisation) { create(:organisation) }
  let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, reservable_online: reservable_online, organisation: organisation) }
  let(:reservable_online) { true }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:today) { Date.new(2019, 9, 19) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, organisation: organisation)
  end
  let(:now) { today.to_time }

  before { travel_to(now) }

  after { travel_back }

  describe "#overlapping_rdvs_or_absences" do
    let(:motif2) { build(:motif, name: "Visite 12 mois", default_duration_in_min: 60, reservable_online: reservable_online, organisation: organisation) }
    let(:creneau) { build(:creneau, starts_at: Time.zone.local(2019, 9, 19, 9, 0), lieu_id: lieu.id, motif: motif2) }

    describe "for absences" do
      subject { creneau.overlapping_rdvs_or_absences([absence]).any? }

      describe "absence overlaps beginning of creneau" do
        let!(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(8, 30), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 30), agent: agent,
                          organisation: organisation)
        end

        it { is_expected.to eq(true) }
      end

      describe "absence overlaps end of creneau" do
        let!(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 30), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 30), agent: agent,
                          organisation: organisation)
        end

        it { is_expected.to eq(true) }
      end

      describe "absence is inside creneau" do
        let!(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 15), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 30), agent: agent,
                          organisation: organisation)
        end

        it { is_expected.to eq(true) }
      end

      describe "absence is before creneau" do
        let!(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(8, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 0), agent: agent,
                          organisation: organisation)
        end

        it { is_expected.to eq(false) }
      end

      describe "absence is after creneau" do
        let!(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(10, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 30), agent: agent,
                          organisation: organisation)
        end

        it { is_expected.to eq(false) }
      end

      describe "absence is around creneau" do
        let!(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(8, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 30), agent: agent,
                          organisation: organisation)
        end

        it { is_expected.to eq(true) }
      end

      describe "absence is like creneau" do
        let!(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 0), agent: agent,
                          organisation: organisation)
        end

        it { is_expected.to eq(true) }
      end
    end

    describe "for rdvs" do
      subject { creneau.overlapping_rdvs_or_absences([rdv]).any? }

      describe "rdv overlaps beginning of creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 8, 30), duration_in_min: 45, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(true) }
      end

      describe "rdv overlaps end of creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 45, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(true) }
      end

      describe "rdv is inside creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 15), duration_in_min: 30, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(true) }
      end

      describe "rdv is before creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 8, 0), duration_in_min: 60, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(false) }
      end

      describe "rdv is after creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 45, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(false) }
      end

      describe "rdv is around creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 8, 0), duration_in_min: 140, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(true) }
      end

      describe "rdv is like creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 60, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(true) }
      end
    end

    describe "mixed absences and rdvs" do
      subject { creneau.overlapping_rdvs_or_absences([rdv1, rdv2, absence]) }

      describe "all overlap creneau" do
        let(:rdv1) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 10, agents: [agent], organisation: organisation) }
        let(:rdv2) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 35, agents: [agent], organisation: organisation) }
        let(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 20), agent: agent,
                          organisation: organisation)
        end

        it "works and be ordered so the first is the one that ends last" do
          expect(subject.count).to eq(3)
          expect(subject.first).to eq(rdv2)
        end
      end
    end
  end

  describe "#respects_min_booking_delay?" do
    subject { creneau.respects_min_booking_delay? }

    context "creneau respects booking delays" do
      let(:creneau) { build(:creneau, :respects_booking_delays) }

      it { is_expected.to be true }
    end

    context "creneau does not respect min booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_min_booking_delay) }

      it { is_expected.to be false }
    end
  end

  describe "#respects_max_booking_delay?" do
    subject { creneau.respects_max_booking_delay? }

    context "creneau respects booking delays" do
      let(:creneau) { build(:creneau, :respects_booking_delays) }

      it { is_expected.to be true }
    end

    context "creneau does not respect max booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_max_booking_delay) }

      it { is_expected.to be false }
    end
  end

  describe "#respects_booking_delays?" do
    subject { creneau.respects_booking_delays? }

    context "creneau respects booking delays" do
      let(:creneau) { build(:creneau, :respects_booking_delays) }

      it { is_expected.to be true }
    end

    context "creneau does not respect min booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_min_booking_delay) }

      it { is_expected.to be false }
    end

    context "creneau does not respect max booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_max_booking_delay) }

      it { is_expected.to be false }
    end
  end
end
