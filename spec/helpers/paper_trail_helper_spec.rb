describe PaperTrailHelper do
  let(:rdv) { create(:rdv) }

  describe "#paper_trail_change_value" do
    subject { helper.paper_trail_change_value(*args) }

    context "nil value" do
      let(:args) { [rdv, "some_value", nil] }

      it { is_expected.to eq "N/A" }
    end

    context "time value" do
      let(:args) { [rdv, "some_value", Time.parse("2020/03/03 10:20")] }

      it { is_expected.to eq "03/03/2020 à 10:20" }
    end

    context "rdv status" do
      let(:args) { [rdv, "status", "unknown"] }

      it { is_expected.to eq "Indéterminé" }
    end

    context "rdv user ids" do
      let(:user1) { create(:user, first_name: "Jeanne", last_name: "Dupont") }
      let(:user2) { create(:user, first_name: "Martine", last_name: "Lalou") }
      let(:args) { [rdv, "user_ids", [user1.id, user2.id]] }

      it { is_expected.to eq "Jeanne DUPONT, Martine LALOU" }
    end

    context "rdv agent ids" do
      let(:agent1) { create(:agent, first_name: "Patricia", last_name: "Allo") }
      let(:agent2) { create(:agent, first_name: "Marco", last_name: "Labat") }
      let(:args) { [rdv, "agent_ids", [agent1.id, agent2.id]] }

      it { is_expected.to eq "Patricia ALLO, Marco LABAT" }
    end
  end
end
