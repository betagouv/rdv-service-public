# frozen_string_literal: true

describe AbsenceBlueprint do
  describe "#render" do
    it "contains an agent" do
      absence = build(:absence, agent: build(:agent, email: "bob@example.com", first_name: "Bob", last_name: "Henri"))
      parsed_absence = JSON.parse(described_class.render(absence, root: :absence))
      expect(parsed_absence["absence"]["agent"]).to eq({
                                                         "email" => "bob@example.com",
                                                         "first_name" => "Bob",
                                                         "last_name" => "Henri",
                                                         "id" => nil
                                                       })
    end

    it "contains rrules" do
      now = Time.zone.parse("2020-12-23 14h00")
      absence = build(:absence, recurrence: Montrose.every(:week, starts: now))
      parsed_absence = JSON.parse(described_class.render(absence, root: :absence))
      expect(parsed_absence["absence"]["rrule"]).to eq("FREQ=WEEKLY;")
    end
  end
end
