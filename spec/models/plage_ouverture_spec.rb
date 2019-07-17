describe PlageOuverture, type: :model do
  describe '#end_after_start' do
    let(:plage_ouverture) { build(:plage_ouverture, start_time: start_time, end_time: end_time) }

    context "start_time < end_time" do
      let(:start_time) { 2.hour.ago }
      let(:end_time) { 1.hour.ago }

      it { expect(plage_ouverture.send(:end_after_start)).to be_nil }
    end

    context "start_time = end_time" do
      let(:start_time) { 2.hour.ago }
      let(:end_time) { start_time }

      it { expect(plage_ouverture.send(:end_after_start)).to eq(["doit être après l'heure de début"]) }
    end

    context "start_time > end_time" do
      let(:start_time) { 2.hour.ago }
      let(:end_time) { 3.hour.ago }

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
