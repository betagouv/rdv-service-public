describe RdvsHelper do
  let(:motif) { build(:motif, name: "Consultation normale") }
  let(:user) { build(:user, first_name: "Marie", last_name: "DENIS") }
  let(:rdv) { build(:rdv, users: [user], motif: motif) }

  describe "#rdv_title_for_user" do
    subject { helper.rdv_title_for_user(rdv, user) }
    it { should eq "Marie DENIS <> Consultation normale" }
  end

  describe "#rdv_title_for_agent" do
    subject { helper.rdv_title_for_agent(rdv) }
    it { should eq "Marie DENIS" }

    context "multiple users" do
      let(:user2) { build(:user, first_name: "Lea", last_name: "CAVE") }
      let(:rdv) { build(:rdv, users: [user, user2], motif: motif) }
      it { should eq "Marie DENIS et Lea CAVE" }
    end

    context "created by user (reservable_online)" do
      let(:rdv) { build(:rdv, users: [user], motif: motif, created_by: :user) }
      it { should eq "@ Marie DENIS" }
    end

    context "phone RDV" do
      let(:rdv) { build(:rdv, :by_phone, users: [user]) }
      it { should eq "Marie DENIS ☎️" }
    end

    context "at home RDV" do
      let(:rdv) { build(:rdv, :at_home, users: [user]) }
      it { should eq "Marie DENIS 🏠" }
    end
  end

  describe "#rdv_time_and_duration" do
    it "return starts_at hour, minutes and duration" do
      rdv = build(:rdv, starts_at: DateTime.new(2020, 3, 23, 12, 46), duration_in_min: 4)
      expect(rdv_time_and_duration(rdv)).to eq("13h46 (4 minutes)")
    end
  end

  describe "#rdv_possible_statuses" do
    it "return À venir et Excusé before rdv's day" do
      now = DateTime.new(2020, 3, 23, 12, 46)
      travel_to(now)
      rdv = build(:rdv, starts_at: (now + 2.days))
      expected = [["À venir", "unknown"], ["Absent excusé", "excused"]]
      expect(rdv_possible_statuses(rdv)).to eq(expected)
    end

    it "return À venir, En salle d'attente, Vu, Non Excusé et Excusé at rdv's day" do
      now = DateTime.new(2020, 3, 23, 12, 46)
      travel_to(now)
      expected = [
        ["À venir", "unknown"],
        ["En salle d'attente", "waiting"],
        ["Absent non excusé", "notexcused"],
        ["Absent excusé", "excused"]
      ]
      rdv = build(:rdv, starts_at: now - 3.hours)
      expect(rdv_possible_statuses(rdv)).to eq(expected)
      rdv = build(:rdv, starts_at: now + 4.hours)
      expect(rdv_possible_statuses(rdv)).to eq(expected)
    end

    it "return Indéterminé, Vu, Non Excusé et Excusé after rdv's day" do
      now = DateTime.new(2020, 3, 23, 12, 46)
      travel_to(now)
      rdv = build(:rdv, starts_at: (now - 2.days))
      expected = [
        ["À renseigner", "unknown"],
        ["Absent non excusé", "notexcused"],
        ["Absent excusé", "excused"]
      ]
      expect(rdv_possible_statuses(rdv)).to eq(expected)
    end
  end
end
