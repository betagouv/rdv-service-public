# frozen_string_literal: true

describe Creneau, type: :model do
  let(:organisation) { create(:organisation) }
  let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, bookable_publicly: bookable_publicly, organisation: organisation) }
  let(:bookable_publicly) { true }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:today) { Time.zone.local(2019, 9, 19) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, organisation: organisation)
  end

  before { travel_to(today) }

  describe "#last_overlapping_event_ends_at" do
    let(:motif2) { build(:motif, name: "Visite 12 mois", default_duration_in_min: 60, bookable_publicly: bookable_publicly, organisation: organisation) }
    let(:creneau) { build(:creneau, starts_at: Time.zone.local(2019, 9, 19, 9, 0), lieu_id: lieu.id, motif: motif2) }

    describe "for absences" do
      subject { creneau.last_overlapping_event_ends_at([absence]) }

      describe "absence overlaps beginning of creneau" do
        let(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(8, 30), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 30), agent: agent)
        end

        it { is_expected.to eq(absence.ends_at) }
      end

      describe "absence overlaps end of creneau" do
        let(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 30), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 30), agent: agent)
        end

        it { is_expected.to eq(absence.ends_at) }
      end

      describe "absence is inside creneau" do
        let(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 15), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 30), agent: agent)
        end

        it { is_expected.to eq(absence.ends_at) }
      end

      describe "absence is before creneau" do
        let(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(8, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 0), agent: agent)
        end

        it { is_expected.to be_nil }
      end

      describe "absence is after creneau" do
        let(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(10, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 30), agent: agent)
        end

        it { is_expected.to be_nil }
      end

      describe "absence is around creneau" do
        let(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(8, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 30), agent: agent)
        end

        it { is_expected.to eq(absence.ends_at) }
      end

      describe "absence is like creneau" do
        let(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 0), agent: agent)
        end

        it { is_expected.to eq(absence.ends_at) }
      end
    end

    describe "for rdvs" do
      subject { creneau.last_overlapping_event_ends_at([rdv]) }

      describe "rdv overlaps beginning of creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 8, 30), duration_in_min: 45, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(rdv.ends_at) }
      end

      describe "rdv overlaps end of creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 45, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(rdv.ends_at) }
      end

      describe "rdv is inside creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 15), duration_in_min: 30, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(rdv.ends_at) }
      end

      describe "rdv is before creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 8, 0), duration_in_min: 60, agents: [agent], organisation: organisation) }

        it { is_expected.to be_nil }
      end

      describe "rdv is after creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 45, agents: [agent], organisation: organisation) }

        it { is_expected.to be_nil }
      end

      describe "rdv is around creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 8, 0), duration_in_min: 140, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(rdv.ends_at) }
      end

      describe "rdv is like creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 60, agents: [agent], organisation: organisation) }

        it { is_expected.to eq(rdv.ends_at) }
      end
    end

    describe "mixed absences and rdvs" do
      subject { creneau.last_overlapping_event_ends_at([rdv1, rdv2, absence]) }

      describe "all overlap creneau" do
        let(:rdv1) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 10, agents: [agent], organisation: organisation) }
        let(:rdv2) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 35, agents: [agent], organisation: organisation) }
        let(:absence) do
          build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 20), agent: agent)
        end

        it "returns the ends_at value of the last event" do
          expect(subject).to eq(rdv2.ends_at)
        end
      end
    end
  end

  describe "#respects_max_public_booking_delay?" do
    subject { creneau.respects_max_public_booking_delay? }

    context "creneau respects booking delays" do
      let(:creneau) { build(:creneau, :respects_booking_delays) }

      it { is_expected.to be true }
    end

    context "creneau does not respect max booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_max_public_booking_delay) }

      it { is_expected.to be false }
    end
  end

  describe "#lieu" do
    it "returns the lieu when the lieu_id is present" do
      expect(build(:creneau, lieu_id: lieu.id).lieu).to eq(lieu)
    end

    it "returns nil when the lieu_id is blank" do
      expect(build(:creneau, lieu_id: nil).lieu).to eq(nil)
    end
  end
end
