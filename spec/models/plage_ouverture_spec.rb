describe PlageOuverture, type: :model do
  describe '#end_after_start' do
    let(:plage_ouverture) { build(:plage_ouverture, start_time: start_time, end_time: end_time) }

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

  describe "::RECURRENCES" do
    it { expect(PlageOuverture::RECURRENCES.size).to eq(3) }

    it { expect(PlageOuverture::RECURRENCES[:never]).to eq("{\"every\":\"day\",\"total\":1}") } # if you change this line, you may migrate some data in db
    it { expect(PlageOuverture::RECURRENCES[:weekly]).to eq("{\"every\":\"week\"}") } # if you change this line, you may migrate some data in db
    it { expect(PlageOuverture::RECURRENCES[:weekly_by_2]).to eq("{\"every\":\"week\",\"interval\":2}") } # if you change this line, you may migrate some data in db
  end

  describe "#occurences_until" do
    subject { plage_ouverture.occurences_until(until_date) }

    context "when until_date is nil" do
      let(:plage_ouverture) { build(:plage_ouverture, first_day: Date.new(2019, 7, 22)) }
      let(:until_date) { nil }

      it "should act as a safeguard and return nil to avoid a possible infinite loop" do
        is_expected.to be nil
      end
    end

    context "when there is no recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, :no_recurrence, first_day: Date.new(2019, 7, 22)) }
      let(:until_date) { Date.new(2019, 7, 28) }

      it do
        expect(subject.size).to eq 1
        expect(subject.first).to eq plage_ouverture.start_at
      end
    end

    context "when there is a weekly recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, :weekly, first_day: Date.new(2019, 7, 22)) }
      let(:until_date) { Date.new(2019, 8, 7) }

      it do
        expect(subject.size).to eq 3
        expect(subject[0]).to eq plage_ouverture.start_at
        expect(subject[1]).to eq(plage_ouverture.start_at + 1.week)
        expect(subject[2]).to eq(plage_ouverture.start_at + 2.weeks)
      end
    end

    context "when there is a weekly recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, :weekly_by_2, first_day: Date.new(2019, 7, 22)) }
      let(:until_date) { Date.new(2019, 8, 7) }

      it do
        expect(subject.size).to eq 2
        expect(subject[0]).to eq plage_ouverture.start_at
        expect(subject[1]).to eq(plage_ouverture.start_at + 2.weeks)
      end
    end
  end
end
