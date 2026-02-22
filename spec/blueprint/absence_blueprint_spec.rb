RSpec.describe AbsenceBlueprint do
  let!(:organisation) { organisations(:default_org) }

  describe "#render" do
    it "contains an agent" do
      agent = create(:agent, email: "bob@example.com", first_name: "Bob", last_name: "Henri", basic_role_in_organisations: [organisation])
      absence = create(:absence, agent:)
      parsed_absence = JSON.parse(described_class.render(absence, root: :absence))
      expect(parsed_absence["absence"]["agent"]).to eq({
                                                         "email" => "bob@example.com",
                                                         "first_name" => "Bob",
                                                         "last_name" => "Henri",
                                                         "id" => agent.id,
                                                       })
    end

    it "contains rrules" do
      Time.zone.parse("2020-12-23 14h00")
      agent = create(:agent, basic_role_in_organisations: [organisation])
      absence = create(:absence, :weekly_on_monday, agent:)
      parsed_absence = JSON.parse(described_class.render(absence, root: :absence))
      expect(parsed_absence["absence"]["rrule"]).to eq("FREQ=WEEKLY;INTERVAL=1;BYDAY=MO;")
    end

    # TODO: Supprimer quand la solution à ce problème est mise en place:
    #   https://github.com/betagouv/rdv-solidarites.fr/pull/3456
    it "contains an organisation" do
      agent = create(:agent, basic_role_in_organisations: [organisation])
      absence = create(:absence, agent:)
      parsed_absence = JSON.parse(described_class.render(absence, root: :absence))

      expect(parsed_absence["absence"]["organisation"]["id"]).to eq(organisation.id)
    end
  end
end
