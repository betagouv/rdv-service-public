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

  describe ".not_expired_for_motif_name_and_lieu" do
    subject { described_class.not_expired_for_motif_name_and_lieu(motif.name, lieu) }

    let!(:service) { create(:service, name: "pmi") }
    let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, service: service, organisation: organisation) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let(:today) { Date.new(2019, 9, 19) }
    let(:six_days_later) { Date.new(2019, 9, 25) }
    let(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }
    let(:agent2) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }
    let(:agent3) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }
    let!(:plage_ouverture) do
      create(:plage_ouverture, :weekly, agent: agent, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), organisation: organisation)
    end

    it { expect(subject).to contain_exactly(plage_ouverture) }

    describe "when PO is not expired" do
      let!(:plage_ouverture) do
        create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: six_days_later, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), organisation: organisation)
      end

      it { expect(subject).to contain_exactly(plage_ouverture) }
    end

    describe "when PO is expired" do
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          motifs: [motif], lieu: lieu, first_day: today - 2.weeks,
          start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11),
          organisation: organisation,
          recurrence: Montrose.every(:week, on: [:monday], starts: today - 2.weeks, until: today - 1.week), expired_cached: true
        )
      end

      it { expect(subject.count).to eq(0) }
    end
  end

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
        let(:plage_ouverture) { create(:plage_ouverture, :no_recurrence, first_day: Date.today, organisation: organisation) }

        it { is_expected.to be false }
      end
    end

    context "with plages regulières" do
      describe "when until is in past" do
        let(:first_day) { Date.today.next_week(:monday) }
        let(:plage_ouverture) do
          create(:plage_ouverture, first_day: first_day, recurrence: Montrose.every(:week, until: DateTime.parse("2020-07-30 10:30").in_time_zone, starts: first_day), organisation: organisation)
        end

        it { is_expected.to be true }
      end

      describe "when until is in future" do
        let(:first_day) { Date.today.next_week(:monday) }
        let(:plage_ouverture) { create(:plage_ouverture, first_day: first_day, recurrence: Montrose.every(:week, until: 2.days.from_now, starts: first_day), organisation: organisation) }

        it { is_expected.to be false }
      end

      describe "when until is today" do
        let(:first_day) { Date.today.next_week(:monday) }
        let(:plage_ouverture) { create(:plage_ouverture, first_day: first_day, recurrence: Montrose.every(:week, until: Date.today, starts: first_day), organisation: organisation) }

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
end
