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

  describe "#starts_at" do
    subject { plage_ouverture.starts_at }

    context "for a plage" do
      let(:plage_ouverture) { create(:plage_ouverture, first_day: Date.new(2019, 7, 22), start_time: Tod::TimeOfDay.new(9)) }

      it { is_expected.to eq(Time.zone.local(2019, 7, 22, 9)) }
    end
  end

  describe "#ends_at" do
    subject { plage_ouverture.ends_at }

    context "for a plage" do
      let(:plage_ouverture) { create(:plage_ouverture, first_day: Date.new(2019, 7, 22), end_time: Tod::TimeOfDay.new(12)) }

      it { is_expected.to eq(Time.zone.local(2019, 7, 22, 12)) }
    end
  end

  describe "#occurences_for" do
    subject { plage_ouverture.occurences_for(date_range) }

    let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 7, 28) }

    context "when there is no recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, :no_recurrence, first_day: Date.new(2019, 7, 22)) }

      it do
        expect(subject.size).to eq 1
        expect(subject.first).to eq plage_ouverture.starts_at
      end

      context "and the first_day is the last of the range" do
        let(:plage_ouverture) { build(:plage_ouverture, :no_recurrence, first_day: date_range.end) }

        it do
          expect(subject.size).to eq 1
          expect(subject.first).to eq plage_ouverture.starts_at
        end
      end
    end

    context "when there is a daily recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 7, 28) }

      it do
        expect(subject.size).to eq 7
        expect(subject[0]).to eq plage_ouverture.starts_at
        expect(subject[1]).to eq(plage_ouverture.starts_at + 1.day)
        expect(subject[2]).to eq(plage_ouverture.starts_at + 2.day)
        expect(subject[3]).to eq(plage_ouverture.starts_at + 3.day)
        expect(subject[4]).to eq(plage_ouverture.starts_at + 4.day)
        expect(subject[5]).to eq(plage_ouverture.starts_at + 5.day)
        expect(subject[6]).to eq(plage_ouverture.starts_at + 6.day)
      end
    end

    context "when there is a weekly recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, :weekly, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 8, 7) }

      it do
        expect(subject.size).to eq 3
        expect(subject[0]).to eq plage_ouverture.starts_at
        expect(subject[1]).to eq(plage_ouverture.starts_at + 1.week)
        expect(subject[2]).to eq(plage_ouverture.starts_at + 2.weeks)
      end
    end

    context "when there is a weekly recurrence with an interval of 2" do
      let(:plage_ouverture) { build(:plage_ouverture, :weekly_by_2, first_day: Date.new(2019, 7, 22)) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 8, 7) }

      it do
        expect(subject.size).to eq 2
        expect(subject[0]).to eq plage_ouverture.starts_at
        expect(subject[1]).to eq(plage_ouverture.starts_at + 2.weeks)
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

  describe ".for_motif_and_lieu_from_date_range" do
    let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30) }
    let!(:lieu) { create(:lieu) }
    let(:today) { Date.new(2019, 9, 19) }
    let(:six_days_later) { Date.new(2019, 9, 25) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }
    let(:agent_ids) { nil }

    subject { PlageOuverture.for_motif_and_lieu_from_date_range(motif.name, lieu, today..six_days_later, agent_ids) }

    it { expect(subject).to contain_exactly(plage_ouverture) }

    describe "when first_day is the last day of time range" do
      let!(:plage_ouverture) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: six_days_later, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

      it { expect(subject).to contain_exactly(plage_ouverture) }
    end

    describe "when first_day is before time range" do
      let!(:plage_ouverture) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: today - 2.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

      it { expect(subject).to contain_exactly(plage_ouverture) }
    end

    describe "when first_day is after time range" do
      let!(:plage_ouverture) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: today + 8.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

      it { expect(subject.count).to eq(0) }
    end

    describe "when agent_ids is passed to filter" do
      let(:agent_ids) { [plage_ouverture.agent_id] }

      it { expect(subject).to contain_exactly(plage_ouverture) }

      describe "and plage_ouverture.agent_id is not passed" do
        let(:agent_ids) { [create(:agent).id, create(:agent).id] }

        it { expect(subject.count).to eq(0) }
      end

      describe "and there is another plage_ouverture" do
        let!(:plage_ouverture2) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: today, agent: create(:agent), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

        it { expect(subject).to contain_exactly(plage_ouverture) }
      end
    end
  end

  describe "#available_motifs" do
    let!(:motif) { create(:motif) }
    let!(:motif2) { create(:motif) }
    let!(:motif3) { create(:motif, :by_phone) }
    let!(:motif4) { create(:motif, organisation: create(:organisation)) }
    let(:plage_ouverture) { build(:plage_ouverture, agent: agent) }

    subject { plage_ouverture.available_motifs }

    describe "for secretaire" do
      let(:agent) { create(:agent, :secretaire) }

      it { is_expected.to contain_exactly(motif3) }
    end

    describe "for other service" do
      let(:agent) { create(:agent, service: motif.service) }

      it { is_expected.to contain_exactly(motif, motif2, motif3) }
    end
  end

  describe "#send_ics_to_agent" do
    let(:plage_ouverture) { build(:plage_ouverture) }

    it "should be called after create" do
      expect(plage_ouverture).to receive(:send_ics_to_agent)
      plage_ouverture.save!
    end

    context "when rdv already exist" do
      let(:plage_ouverture) { create(:plage_ouverture) }

      it "should not be called" do
        expect(plage_ouverture).not_to receive(:send_ics_to_agent)
        plage_ouverture.save!
      end
    end

    it "calls PlageOuvertureMailer to send email to agetn" do
      expect(PlageOuvertureMailer).to receive(:send_ics_to_agent).with(plage_ouverture).and_return(double(deliver_later: nil))
      plage_ouverture.save!
    end
  end
end
