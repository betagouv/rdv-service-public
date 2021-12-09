# frozen_string_literal: true

describe OrganisationsHelper do
  describe "#show_checklist?" do
    context "for agent with admin access" do
      it "returns true with a 4 days old organisation" do
        now = Time.zone.parse("2021-11-23 10:56")
        travel_to(now)
        organisation = create(:organisation, created_at: now - 4.days)
        agent = create(:agent, admin_role_in_organisations: [organisation])
        expect(show_checklist?(organisation, agent)).to be_truthy
      end

      it "returns false with an 8 days old organisation" do
        now = Time.zone.parse("2021-11-23 10:56")
        travel_to(now)
        organisation = create(:organisation, created_at: now - 8.days)
        agent = create(:agent, admin_role_in_organisations: [organisation])
        expect(show_checklist?(organisation, agent)).to be_falsy
      end
    end

    it "returns false for agent without admin access" do
      now = Time.zone.parse("2021-11-23 10:56")
      travel_to(now)
      organisation = create(:organisation, created_at: now - 8.days)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      expect(show_checklist?(organisation, agent)).to be_falsy
    end
  end

  describe "#organisation_home_path" do
    it "returns first steps page if show checklist" do
      now = Time.zone.parse("2021-11-23 10:56")
      travel_to(now)
      organisation = create(:organisation, created_at: now - 4.days)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      expect(organisation_home_path(organisation, agent)).to eq(admin_organisation_setup_checklist_path(organisation))
    end

    it "returns agenda page if not show checklist" do
      now = Time.zone.parse("2021-11-23 10:56")
      travel_to(now)
      organisation = create(:organisation, created_at: now - 8.days)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      expect(organisation_home_path(organisation, agent)).to eq(admin_organisation_agent_agenda_path(organisation, agent))
    end
  end
end
