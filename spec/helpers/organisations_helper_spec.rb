# frozen_string_literal: true

describe OrganisationsHelper do
  let(:organisation) { create(:organisation, created_at: 21.days.ago) }

  describe "#show_checklist?" do
    before { travel_to(Time.zone.parse("2021-11-23 10:56")) }

    context "for agent with admin access" do
      it "returns true with an agent using the application for 4 days" do
        agent = create(:agent, admin_role_in_organisations: [organisation],
                               invitation_accepted_at: 4.days.ago)
        expect(show_checklist?(organisation, agent)).to be_truthy
      end

      it "returns false with an agent using the application for 8 days" do
        agent = create(:agent, admin_role_in_organisations: [organisation],
                               invitation_accepted_at: 8.days.ago)
        expect(show_checklist?(organisation, agent)).to be_falsy
      end
    end

    it "returns false for agent without admin access" do
      agent = create(:agent, basic_role_in_organisations: [organisation],
                             invitation_accepted_at: 4.days.ago)
      expect(show_checklist?(organisation, agent)).to be_falsy
    end

    context "for a conseiller numérique" do
      let(:service_cnfs) { create(:service, :conseiller_numerique) }

      it "returns true with a 21 days old organisation and 13 days old agent, until the agent has 2 rdvs" do
        agent = create(:agent, admin_role_in_organisations: [organisation],
                               invitation_accepted_at: 13.days.ago,
                               service: service_cnfs)

        expect(show_checklist?(organisation, agent)).to be_truthy

        create_list(:rdv, 2, agents: [agent])

        expect(show_checklist?(organisation, agent)).to be_falsey
      end
    end
  end

  describe "#organisation_home_path" do
    it "returns first steps page if show checklist" do
      agent = create(:agent, admin_role_in_organisations: [organisation],
                             invitation_accepted_at: 4.days.ago)
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
