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



    end
  describe "#occurences_for" do
    subject { plage_ouverture.occurences_for(date_range) }

    context "when there is no recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, :no_recurrence, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 7, 28) }

      it do
        expect(subject.size).to eq 1
        expect(subject.first).to eq plage_ouverture.start_at
      end
    end

    context "when there is a daily recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 7, 28) }

      it do
        expect(subject.size).to eq 7
        expect(subject[0]).to eq plage_ouverture.start_at
        expect(subject[1]).to eq(plage_ouverture.start_at + 1.day)
        expect(subject[2]).to eq(plage_ouverture.start_at + 2.day)
        expect(subject[3]).to eq(plage_ouverture.start_at + 3.day)
        expect(subject[4]).to eq(plage_ouverture.start_at + 4.day)
        expect(subject[5]).to eq(plage_ouverture.start_at + 5.day)
        expect(subject[6]).to eq(plage_ouverture.start_at + 6.day)
      end
    end

    context "when there is a weekly recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, :weekly, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 8, 7) }

      it do
        expect(subject.size).to eq 3
        expect(subject[0]).to eq plage_ouverture.start_at
        expect(subject[1]).to eq(plage_ouverture.start_at + 1.week)
        expect(subject[2]).to eq(plage_ouverture.start_at + 2.weeks)
      end
    end

    context "when there is a weekly recurrence with an interval of 2" do
      let(:plage_ouverture) { build(:plage_ouverture, :weekly_by_2, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 8, 7) }

      it do
        expect(subject.size).to eq 2
        expect(subject[0]).to eq plage_ouverture.start_at
        expect(subject[1]).to eq(plage_ouverture.start_at + 2.weeks)
      end
    end

    context "when there is a daily recurrence and until is set" do
      let(:plage_ouverture) { build(:plage_ouverture, first_day: Date.new(2019, 7, 22), recurrence: Montrose.daily.until(Date.new(2019, 8, 5)).to_json) }
      let(:date_range) { Date.new(2019, 8, 5)..Date.new(2019, 8, 11) }

      it do
        expect(subject.size).to eq 1
        expect(subject[0]).to eq(Time.zone.local(2019, 8, 5, 8))
      end
    end
  end
end
