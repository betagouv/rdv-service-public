# frozen_string_literal: true

describe PlageOuverture, type: :model do
  let!(:organisation) { create(:organisation) }

  describe "#end_after_start" do
    let(:plage_ouverture) { build(:plage_ouverture, start_time: start_time, end_time: end_time, organisation: organisation) }

    context "start_time < end_time" do
      let(:start_time) { Tod::TimeOfDay.new(7) }
      let(:end_time) { Tod::TimeOfDay.new(8) }

      it { expect(plage_ouverture.send(:end_after_start)).to be_nil }
    end

    context "start_time = end_time" do
      let(:start_time) { Tod::TimeOfDay.new(7) }
      let(:end_time) { start_time }

      it { expect(plage_ouverture.send(:end_after_start)).to eq(["doit être après l'heure de début"]) }
    end

    context "start_time > end_time" do
      let(:start_time) { Tod::TimeOfDay.new(7, 30) }
      let(:end_time) { Tod::TimeOfDay.new(7) }

      it { expect(plage_ouverture.send(:end_after_start)).to eq(["doit être après l'heure de début"]) }
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
      describe "when until is in past" do
        let(:first_day) { Time.zone.today.next_week(:monday) }
        let(:plage_ouverture) do
          create(:plage_ouverture, first_day: first_day, recurrence: Montrose.every(:week, until: DateTime.parse("2020-07-30 10:30").in_time_zone, starts: first_day), organisation: organisation)
        end

        it { is_expected.to be true }
      end

      describe "when until is in future" do
        let(:first_day) { Time.zone.today.next_week(:monday) }
        let(:plage_ouverture) { create(:plage_ouverture, first_day: first_day, recurrence: Montrose.every(:week, until: 2.days.from_now, starts: first_day), organisation: organisation) }

        it { is_expected.to be false }
      end

      describe "when until is today" do
        let(:first_day) { Time.zone.today.next_week(:monday) }
        let(:plage_ouverture) { create(:plage_ouverture, first_day: first_day, recurrence: Montrose.every(:week, until: Time.zone.today, starts: first_day), organisation: organisation) }

        it { is_expected.to be false }
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
          recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18), on: [:wednesday]).to_json,
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
          recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18), interval: 2, on: [:wednesday]).to_json,
          first_day: Date.new(2020, 11, 18), # a wednesday
          start_time: Tod::TimeOfDay.new(14),
          end_time: Tod::TimeOfDay.new(18)
        )
      end

      context "for a wednesday 1 week later" do
        let(:date) { Date.new(2020, 11, 25) }

        it { is_expected.to eq false }
      end

      # TODO : pending before https://github.com/rossta/montrose/pull/132
      context "for a wednesday 2 weeks later", pending: true do
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

  describe "#in" do
    let(:today) { Date.new(2021, 10, 3) }
    let(:range) { Date.new(2021, 10, 25)..Date.new(2021, 10, 29) }

    before do
      travel_to(today)
    end

    it "returns po when no recurrence and first_day in range" do
      plage_ouverture = create(:plage_ouverture, first_day: Date.new(2021, 10, 26), recurrence: nil)
      expect(described_class.in_range(range)).to eq([plage_ouverture])
    end

    it "dont returns po when no recurrence and first_day after range" do
      create(:plage_ouverture, first_day: Date.new(2021, 11, 26), recurrence: nil)
      expect(described_class.in(range)).to eq([])
    end

    it "dont returns po when no recurrence and first_day before range" do
      create(:plage_ouverture, first_day: Date.new(2021, 9, 26), recurrence: nil)
      expect(described_class.in(range)).to eq([])
    end

    it "returns po with recurrence start in range" do
      first_day = Date.new(2021, 9, 26)
      po = create(:plage_ouverture, first_day: first_day, recurrence: Montrose.every(:week, on: ["monday"], starts: first_day))
      expect(described_class.in(range)).to eq([po])
    end

    it "returns po with recurrence ends in range" do
      first_day = range.begin - 1.month
      po = create(:plage_ouverture, first_day: first_day,
                                    recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.end - 2.days))
      expect(described_class.in(range)).to eq([po])
    end

    it "returns po with recurrence start before range and end after range" do
      first_day = range.begin - 1.day
      po = create(:plage_ouverture, first_day: first_day,
                                    recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.end + 2.days))
      expect(described_class.in(range)).to eq([po])
    end

    it "dont returns po with recurrence end before range" do
      first_day = range.begin - 2.months
      create(:plage_ouverture, first_day: first_day,
                               recurrence: Montrose.every(:week, on: ["monday"], starts: first_day, until: range.begin - 3.days))
      expect(described_class.in(range)).to eq([])
    end

    it "dont returns po with recurrence start after range" do
      first_day = range.end + 4.days
      create(:plage_ouverture, first_day: first_day,
                               recurrence: Montrose.every(:week, on: ["monday"], starts: first_day))
      expect(described_class.in(range)).to eq([])
    end
  end
end
