describe Creneau, type: :model do
  let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, online: online) }
  let(:online) { true }
  let!(:lieu) { create(:lieu) }
  let(:today) { Date.new(2019, 9, 19) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }
  let(:agent) { plage_ouverture.agent }
  let(:now) { today.to_time }

  before { travel_to(now) }
  after { travel_back }

  describe "#overlaps_rdv_or_absence?" do
    let(:motif2) { build(:motif, name: "Visite 12 mois", default_duration_in_min: 60, online: online) }
    let(:creneau) { build(:creneau, starts_at: Time.zone.local(2019, 9, 19, 9, 0), lieu_id: lieu.id, motif: motif2) }

    describe "for absences" do
      subject { creneau.overlaps_rdv_or_absence?([absence]) }

      describe "absence overlaps beginning of creneau" do
        let!(:absence) { build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(8, 30), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 30), agent: agent) }
        it { is_expected.to eq(true) }
      end

      describe "absence overlaps end of creneau" do
        let!(:absence) { build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 30), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 30), agent: agent) }
        it { is_expected.to eq(true) }
      end

      describe "absence is inside creneau" do
        let!(:absence) { build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 15), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 30), agent: agent) }
        it { is_expected.to eq(true) }
      end

      describe "absence is before creneau" do
        let!(:absence) { build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(8, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(9, 0), agent: agent) }
        it { is_expected.to eq(false) }
      end

      describe "absence is after creneau" do
        let!(:absence) { build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(10, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 30), agent: agent) }
        it { is_expected.to eq(false) }
      end

      describe "absence is around creneau" do
        let!(:absence) { build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(8, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 30), agent: agent) }
        it { is_expected.to eq(true) }
      end

      describe "absence is like creneau" do
        let!(:absence) { build(:absence, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 0), agent: agent) }
        it { is_expected.to eq(true) }
      end
    end

    describe "for rdvs" do
      subject { creneau.overlaps_rdv_or_absence?([rdv]) }

      describe "rdv overlaps beginning of creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 8, 30), duration_in_min: 45, agents: [agent]) }
        it { is_expected.to eq(true) }
      end

      describe "rdv overlaps end of creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 45, agents: [agent]) }
        it { is_expected.to eq(true) }
      end

      describe "rdv is inside creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 15), duration_in_min: 30, agents: [agent]) }
        it { is_expected.to eq(true) }
      end

      describe "rdv is before creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 8, 0), duration_in_min: 60, agents: [agent]) }
        it { is_expected.to eq(false) }
      end

      describe "rdv is after creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 45, agents: [agent]) }
        it { is_expected.to eq(false) }
      end

      describe "rdv is around creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 8, 0), duration_in_min: 140, agents: [agent]) }
        it { is_expected.to eq(true) }
      end

      describe "rdv is like creneau" do
        let(:rdv) { build(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 60, agents: [agent]) }
        it { is_expected.to eq(true) }
      end
    end
  end

  describe "#available_plages_ouverture" do
    let(:creneau) { Creneau.new(starts_at: Time.zone.local(2019, 9, 19, 9, 0), lieu_id: lieu.id, motif: motif) }

    subject { creneau.available_plages_ouverture }

    it { should contain_exactly(plage_ouverture) }

    describe "with an other plage_ouverture for this motif" do
      let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

      it { should contain_exactly(plage_ouverture, plage_ouverture2) }
    end

    describe "with an other plage_ouverture with another motif" do
      let(:motif2) { build(:motif, name: "Visite 12 mois", default_duration_in_min: 60, online: online) }
      let!(:plage_ouverture3) { create(:plage_ouverture, title: "Permanence visite 12 mois", motifs: [motif2], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

      it { should contain_exactly(plage_ouverture) }
    end

    describe "with an other plage_ouverture but not opened the right time" do
      let!(:plage_ouverture4) { build(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(18)) }

      it { should contain_exactly(plage_ouverture) }
    end

    describe "with a rdv" do
      let!(:rdv) { create(:rdv, agents: [plage_ouverture.agent], starts_at: creneau.starts_at, duration_in_min: 30) }

      it { should eq([]) }

      describe "which is cancelled" do
        let!(:rdv) { build(:rdv, agents: [plage_ouverture.agent], starts_at: creneau.starts_at, duration_in_min: 30, cancelled_at: 2.days.ago) }

        it { should contain_exactly(plage_ouverture) }
      end
    end
  end

  describe ".next_availability_for_motif_and_lieu" do
    let(:motif_name) { motif.name }
    let(:from) { today }

    subject do
      Creneau.next_availability_for_motif_and_lieu(motif_name, lieu, from)
    end

    it { expect(subject.starts_at).to eq(Time.zone.local(2019, 9, 19, 9, 0)) }

    describe "with not online motif" do
      let(:online) { false }

      it { should eq(nil) }
    end

    describe "with absence" do
      let!(:absence) { create(:absence, agent: agent, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(12, 0)) }

      it { should eq(nil) }

      describe "when plage_ouverture is recurrence" do
        before { plage_ouverture.update(recurrence: Montrose.monthly.to_json) }

        it { expect(subject.starts_at).to eq(Time.zone.local(2019, 10, 19, 9, 0)) }
      end
    end

    describe "with rdv" do
      let!(:rdv) { create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 120, agents: [agent]) }

      it { should eq(nil) }

      context "which is cancelled" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, agents: [agent], cancelled_at: Time.zone.local(2019, 9, 20, 9, 30)) }

        it { expect(subject.starts_at).to eq(Time.zone.local(2019, 9, 19, 9, 0)) }
      end

      describe "when plage_ouverture is recurrence" do
        before { plage_ouverture.update(recurrence: Montrose.monthly.to_json) }

        it { expect(subject.starts_at).to eq(Time.zone.local(2019, 10, 19, 9, 0)) }
      end
    end
  end

  describe "#respects_min_booking_delay?" do
    subject { creneau.respects_min_booking_delay? }

    context "creneau respects booking delays" do
      let(:creneau) { build(:creneau, :respects_booking_delays) }
      it { should be true }
    end

    context "creneau does not respect min booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_min_booking_delay) }
      it { should be false }
    end
  end

  describe "#respects_max_booking_delay?" do
    subject { creneau.respects_max_booking_delay? }

    context "creneau respects booking delays" do
      let(:creneau) { build(:creneau, :respects_booking_delays) }
      it { should be true }
    end

    context "creneau does not respect max booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_max_booking_delay) }
      it { should be false }
    end
  end

  describe "#respects_booking_delays?" do
    subject { creneau.respects_booking_delays? }

    context "creneau respects booking delays" do
      let(:creneau) { build(:creneau, :respects_booking_delays) }
      it { should be true }
    end

    context "creneau does not respect min booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_min_booking_delay) }
      it { should be false }
    end

    context "creneau does not respect max booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_max_booking_delay) }
      it { should be false }
    end
  end

  describe "#available_with_rdvs_and_absences?" do
    context "does not respect min or max booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_min_booking_delay) }
      context "not for agents (default)" do
        subject { creneau.available_with_rdvs_and_absences?([], []) }
        it { should eq false }
      end
      context "for agents" do
        subject { creneau.available_with_rdvs_and_absences?([], [], for_agents: true) }
        it { should eq true }
      end
    end
  end
end
