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

    context "created by user (online)" do
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
end
