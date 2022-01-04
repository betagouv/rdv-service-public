# frozen_string_literal: true

describe PlageOuverture, type: :model do
  let!(:organisation) { create(:organisation) }

  describe "#end_after_start" do
    subject { plage_ouverture.send(:end_after_start) }

    let(:plage_ouverture) { build(:plage_ouverture, start_time: start_time, end_time: end_time, organisation: organisation) }

    context "start_time < end_time" do
      let(:start_time) { Tod::TimeOfDay.new(7) }
      let(:end_time) { Tod::TimeOfDay.new(8) }

      it { expect(subject).to be_nil }
    end

    context "start_time = end_time" do
      let(:start_time) { Tod::TimeOfDay.new(7) }
      let(:end_time) { start_time }

      it { expect(subject&.type).to eq(:must_be_after_start_time) }
    end

    context "start_time > end_time" do
      let(:start_time) { Tod::TimeOfDay.new(7, 30) }
      let(:end_time) { Tod::TimeOfDay.new(7) }

      it { expect(subject&.type).to eq(:must_be_after_start_time) }
    end
  end

  it_behaves_like "recurrence"

  describe "#expired?" do
    subject { plage_ouverture.expired? }

    context "with exceptionnelles plages" do
      describe "when first_day is in past" do
        let(:plage_ouverture) { create(:plage_ouverture, :no_recurrence, first_day: Date.parse("2020-07-30"), organisation: organisation) }

        it { is_expected.to be true }
      end

      describe "when first_day is in future" do
        let(:plage_ouverture) { create(:plage_ouverture, :no_recurrence, first_day: 2.days.from_now, organisation: organisation) }

        it { is_expected.to be false }
      end

      describe "when first_day is today" do
        let(:plage_ouverture) { create(:plage_ouverture, :no_recurrence, first_day: Time.zone.today, organisation: organisation) }

        it { is_expected.to be false }
      end
    end

    context "with plages regulières" do
      it "returns true when until is in past" do
        now = Time.zone.parse("20200730 10:30")
        travel_to(now)
        plage_ouverture = create(:plage_ouverture, first_day: now - 3.weeks, recurrence: Montrose.every(:week, until: now - 1.week, starts: now - 3.weeks), organisation: organisation)
        expect(plage_ouverture.expired?).to be true
      end

      it "returns false when until is in future" do
        now = Time.zone.parse("20200730 10:30")
        travel_to(now)
        plage_ouverture = create(:plage_ouverture, first_day: now - 3.weeks, recurrence: Montrose.every(:week, until: now + 1.week, starts: now - 3.weeks), organisation: organisation)
        expect(plage_ouverture.expired?).to be false
      end

      it "returns false when until is today" do
        now = Time.zone.parse("20200730 10:30")
        travel_to(now)
        plage_ouverture = create(:plage_ouverture, first_day: now - 3.weeks, recurrence: Montrose.every(:week, until: now, starts: now - 3.weeks), organisation: organisation)
        expect(plage_ouverture.expired?).to be false
      end
    end
  end

  describe "#available_motifs" do
    subject { plage_ouverture.available_motifs }

    let!(:orga2) { create(:organisation) }
    let!(:service) { create(:service) }
    let!(:motif) { create(:motif, name: "Accueil", service: service, organisation: organisation) }
    let!(:motif2) { create(:motif, name: "Suivi", service: service, organisation: organisation) }
    let!(:motif3) { create(:motif, :for_secretariat, name: "Test", service: service, organisation: organisation) }
    let!(:motif4) { create(:motif, name: "other orga", service: service, organisation: orga2) }
    let(:plage_ouverture) { build(:plage_ouverture, agent: agent, organisation: organisation, motifs: [motif]) }

    describe "for secretaire" do
      let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif3) }
    end

    describe "for other service" do
      let(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif, motif2, motif3) }
    end
  end

  describe "#covers_date?" do
    subject { plage_ouverture.covers_date?(date) }

    describe "PO weekly wednesdays PM" do
      let(:plage_ouverture) do
        build(
          :plage_ouverture,
          recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18).in_time_zone, interval: 1, on: [:wednesday]).to_json,
          first_day: Date.new(2020, 11, 18), # a wednesday
          start_time: Tod::TimeOfDay.new(14),
          end_time: Tod::TimeOfDay.new(18)
        )
      end

      context "for a wednesday later" do
        let(:date) { Date.new(2020, 12, 2) }

        it { is_expected.to eq true }
      end

      context "for a wednesday before" do
        let(:date) { Date.new(2020, 11, 11) }

        it { is_expected.to eq false }
      end

      context "for a thursday later" do
        let(:date) { Date.new(2020, 12, 3) }

        it { is_expected.to eq false }
      end
    end

    describe "PO weekly wednesdays PM with an end date" do
      let(:plage_ouverture) do
        build(
          :plage_ouverture,
          recurrence: Montrose.every(:week, on: [:wednesday], starts: Date.new(2020, 11, 18).in_time_zone, until: Date.new(2020, 12, 9).in_time_zone).to_json,
          first_day: Date.new(2020, 11, 18), # a wednesday
          start_time: Tod::TimeOfDay.new(14),
          end_time: Tod::TimeOfDay.new(18)
        )
      end

      context "for a wednesday before end date" do
        let(:date) { Date.new(2020, 12, 2) }

        it { is_expected.to eq true }
      end

      context "for the end wednesday" do
        let(:date) { Date.new(2020, 12, 9) }

        it { is_expected.to eq true }
      end

      context "for a wednesday after the end" do
        let(:date) { Date.new(2020, 12, 16) }

        it { is_expected.to eq false }
      end
    end

    describe "PO every 2 weeks wednesdays PM" do
      let(:plage_ouverture) do
        build(
          :plage_ouverture,
          recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18).in_time_zone, interval: 2, on: [:wednesday]).to_json,
          first_day: Date.new(2020, 11, 18), # a wednesday
          start_time: Tod::TimeOfDay.new(14),
          end_time: Tod::TimeOfDay.new(18)
        )
      end

      context "for a wednesday 1 week later" do
        let(:date) { Date.new(2020, 11, 25) }

        it { is_expected.to eq false }
      end

      context "for a wednesday 2 weeks later" do
        let(:date) { Date.new(2020, 12, 2) }

        it { is_expected.to eq true }
      end
    end

    describe "exceptionnelle" do
      let(:plage_ouverture) do
        build(
          :plage_ouverture,
          recurrence: nil,
          first_day: Date.new(2020, 11, 18), # a wednesday
          start_time: Tod::TimeOfDay.new(14),
          end_time: Tod::TimeOfDay.new(18)
        )
      end

      context "same day" do
        let(:date) { Date.new(2020, 11, 18) }

        it { is_expected.to eq true }
      end

      context "other date" do
        let(:date) { Date.new(2020, 11, 25) }

        it { is_expected.to eq false }
      end
    end
  end

  describe "#overlaps_with_time_slot?" do
    subject { plage_ouverture.overlaps_with_time_slot?(time_slot) }

    describe "plage ouverture 14h-18h" do
      let(:plage_ouverture) do
        build(:plage_ouverture, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(18))
      end
      let!(:time_slot) { TimeSlot.new(Time.zone.parse("2020-12-2 16:00"), Time.zone.parse("2020-12-2 17:00")) }

      before do
        allow(plage_ouverture).to receive(:covers_date?)
          .with(Date.new(2020, 12, 2))
          .and_return(date_is_covered)
        plage_ouverture_time_slot = instance_double(TimeSlot)
        allow(TimeSlot).to receive(:new)
          .with(Time.zone.parse("2020-12-2 14:00"), Time.zone.parse("2020-12-2 18:00"))
          .and_return(plage_ouverture_time_slot)
        allow(plage_ouverture_time_slot).to receive(:intersects?)
          .with(time_slot)
          .and_return(time_slots_intersect)
      end

      context "date is covered & time slots intersect" do
        let(:date_is_covered) { true }
        let(:time_slots_intersect) { true }

        it { is_expected.to eq true }
      end

      context "date is not covered but time slots intersect" do
        let(:date_is_covered) { false }
        let(:time_slots_intersect) { true }

        it { is_expected.to eq false }
      end

      context "date not covered but time slots do not intersect" do
        let(:date_is_covered) { true }
        let(:time_slots_intersect) { false }

        it { is_expected.to eq false }
      end

      context "date is not covered and time slots do not intersect" do
        let(:date_is_covered) { false }
        let(:time_slots_intersect) { false }

        it { is_expected.to eq false }
      end
    end
  end
end
