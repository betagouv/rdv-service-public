RSpec.describe PlageOuverture, type: :model do
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

  describe "lieu presence" do
    context "when no motif requires a lieu" do
      it "is valid without a lieu" do
        plage_ouverture = build(:plage_ouverture, lieu: nil, motifs: [create(:motif, :by_phone), create(:motif, :at_home)])
        expect(plage_ouverture).to be_valid
      end
    end

    context "when at least one motif requires a lieu" do
      it "is invalid without a lieu" do
        plage_ouverture = build(:plage_ouverture, lieu: nil, motifs: [create(:motif, :by_phone), create(:motif, :at_public_office)])
        expect(plage_ouverture).not_to be_valid
      end
    end
  end

  describe "lieu_is_enabled" do
    subject { plage_ouverture.errors }

    let(:plage_ouverture) { build :plage_ouverture, lieu: lieu }

    before { plage_ouverture.validate }

    context "invalid if lieu is disabled" do
      let(:lieu) { build :lieu, availability: :disabled }

      it { is_expected.to be_of_kind(:lieu, :must_be_enabled) }
    end

    context "invalid if lieu is single_use" do
      let(:lieu) { build :lieu, availability: :single_use }

      it { is_expected.to be_of_kind(:lieu, :must_be_enabled) }
    end

    context "valid if lieu is enabled" do
      let(:lieu) { build :lieu, availability: :enabled }

      it { is_expected.to be_empty }
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

    describe "PO once_a_week wednesdays PM" do
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

        it { is_expected.to be true }
      end

      context "for a wednesday before" do
        let(:date) { Date.new(2020, 11, 11) }

        it { is_expected.to be false }
      end

      context "for a thursday later" do
        let(:date) { Date.new(2020, 12, 3) }

        it { is_expected.to be false }
      end
    end

    describe "PO once_a_week wednesdays PM with an end date" do
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

        it { is_expected.to be true }
      end

      context "for the end wednesday" do
        let(:date) { Date.new(2020, 12, 9) }

        it { is_expected.to be true }
      end

      context "for a wednesday after the end" do
        let(:date) { Date.new(2020, 12, 16) }

        it { is_expected.to be false }
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

        it { is_expected.to be false }
      end

      context "for a wednesday 2 weeks later" do
        let(:date) { Date.new(2020, 12, 2) }

        it { is_expected.to be true }
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

        it { is_expected.to be true }
      end

      context "other date" do
        let(:date) { Date.new(2020, 11, 25) }

        it { is_expected.to be false }
      end
    end
  end

  describe "#overlapping_range" do
    let(:now) { Time.zone.parse("2022-12-27 11:00") }

    before { travel_to(now) }

    it "return empty when PlageOuverture outside range" do
      range = (now)..(now + 30.minutes)
      create(:plage_ouverture, first_day: now.to_date, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(10))
      create(:plage_ouverture, first_day: now.to_date, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(17))
      expect(described_class.overlapping_range(range)).to be_empty
    end

    it "return plage_ouverture when ends in range" do
      range = (now + 1.week)..(now + 1.week + 30.minutes)
      plage_ouverture = create(:plage_ouverture, first_day: (now + 1.week).to_date, start_time: Tod::TimeOfDay.new(10, 45), end_time: Tod::TimeOfDay.new(11, 45))
      expect(described_class.overlapping_range(range)).to eq([plage_ouverture])
    end

    it "return plage_ouverture when starts in range" do
      range = now..(now + 30.minutes)
      plage_ouverture = create(:plage_ouverture, first_day: now.to_date, start_time: Tod::TimeOfDay.new(11, 15), end_time: Tod::TimeOfDay.new(12, 15))
      expect(described_class.overlapping_range(range)).to eq([plage_ouverture])
    end

    it "return plage_ouverture when one occurrence overlapping range" do
      range = now..(now + 30.minutes)
      plage_ouverture = create(:plage_ouverture, first_day: (now - 2.weeks).to_date, start_time: Tod::TimeOfDay.new(10, 45), end_time: Tod::TimeOfDay.new(11, 45),
                                                 recurrence: Montrose.every(:week, on: ["tuesday"], starts: (now - 2.weeks).to_date, interval: 1))
      expect(described_class.overlapping_range(range)).to eq([plage_ouverture])
    end

    it "return empty when plage_ouverture occurrence doesnt overlapping range" do
      now = Time.zone.parse("2022-12-27 11:00")
      travel_to(now)
      range = (now + 1.week)..(now + 1.week + 30.minutes)
      create(:plage_ouverture, first_day: (now - 1.week).to_date,
                               start_time: Tod::TimeOfDay.new(10, 45), \
                               end_time: Tod::TimeOfDay.new(11, 45), \
                               recurrence: Montrose.every(:month, day: { Tuesday: [2] }, starts: (now - 1.week).to_date, interval: 1))
      expect(described_class.overlapping_range(range)).to be_empty
    end
  end

  describe "first day realistic validations" do
    context "first day before 2018" do
      let(:plage_ouverture) { build(:plage_ouverture, first_day: Date.new(2017, 12, 24)) }

      it "should be invalid" do
        expect(plage_ouverture).to be_invalid
        expect(plage_ouverture.errors.full_messages.first).to eq("Le premier jour ne peut pas être avant 2018")
      end
    end

    context "first day more than 5 years from now" do
      let(:plage_ouverture) { build(:plage_ouverture, first_day: Date.new(2100, 12, 24)) }

      it "should be invalid" do
        expect(plage_ouverture).to be_invalid
        expect(plage_ouverture.errors.full_messages.first).to eq("Le premier jour ne peut pas être dans plus de 5 ans")
      end
    end

    context "first day is reasonable" do
      let(:plage_ouverture) { build(:plage_ouverture, first_day: Date.new(2020, 12, 24)) }

      it "should be valid" do
        expect(plage_ouverture).to be_valid
      end
    end
  end

  describe "recurrence_ends_at realistic validations" do
    context "recurrence_ends_at before 2018" do
      let(:plage_ouverture) { build(:plage_ouverture, :once_a_week, first_day: Date.new(2015, 12, 24), recurrence_ends_at: Date.new(2017, 12, 24).at_noon) }

      it "should be invalid" do
        expect(plage_ouverture).to be_invalid
        expect(plage_ouverture.errors.full_messages).to include("Dernier jour ne peut pas être avant 2018")
      end
    end

    context "recurrence_ends_at more than 5 years from now" do
      let(:plage_ouverture) { build(:plage_ouverture, :once_a_week, first_day: Date.new(2020, 12, 1), recurrence_ends_at: Date.new(2100, 12, 24)) }

      it "should be invalid" do
        expect(plage_ouverture).to be_invalid
        expect(plage_ouverture.errors.full_messages).to include("Dernier jour ne peut pas être dans plus de 5 ans")
      end
    end

    context "recurrence_ends_at is reasonable" do
      let(:plage_ouverture) { build(:plage_ouverture, :once_a_week, first_day: Date.new(2020, 12, 1), recurrence_ends_at: Date.new(2020, 12, 24)) }

      it "should be valid" do
        expect(plage_ouverture).to be_valid
      end
    end
  end
end
