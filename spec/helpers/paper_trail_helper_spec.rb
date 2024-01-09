describe PaperTrailHelper do
  describe "#paper_trail_change_value" do
    it "returns N/A when nil value" do
      expect(helper.paper_trail_change_value("some_value", nil)).to eq("N/A")
    end

    it "returns formatted time value when column looks like a datetime" do
      expect(helper.paper_trail_change_value("thingified_at", "2020/03/03 10:20")).to eq("03/03/2020 à 10:20")
    end

    it "returns formatted date when column looks like a date" do
      expect(helper.paper_trail_change_value("thingification_day", "2020-05-25")).to eq("25 mai 2020")
    end

    it "returns rdv status when property status and resource rdv" do
      expect(helper.paper_trail_change_value("status", "unknown")).to eq("État indéterminé")
    end

    xit "returns rdv user ids when property user_ids for rdv resource" do
      user1 = create(:user, first_name: "Jeanne", last_name: "Dupont")
      user2 = create(:user, first_name: "Martine", last_name: "Lalou")
      expect(helper.paper_trail_change_value("user_ids", [user1.id, user2.id])).to eq("Jeanne DUPONT, Martine LALOU")
    end

    xit "returns rdv agent ids when property agent_ids with rdv ressource" do
      agent1 = create(:agent, first_name: "Patricia", last_name: "Allo")
      agent2 = create(:agent, first_name: "Marco", last_name: "Labat")

      expect(helper.paper_trail_change_value("agent_ids", [agent1.id, agent2.id])).to eq("Patricia ALLO, Marco LABAT")
    end

    it "returns stringified value when passed an unknown property of arbitrary type" do
      expect(helper.paper_trail_change_value("some_value", :some_symbol)).to eq("some_symbol")
    end
  end
end
