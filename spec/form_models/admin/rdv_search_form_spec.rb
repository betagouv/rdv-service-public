# frozen_string_literal: true

describe Admin::RdvSearchForm do
  describe "#lieu" do
    it "have a lieu when given" do
      lieu = create(:lieu)
      agent_rdv_search_form = described_class.new(lieu_id: lieu.id)
      expect(agent_rdv_search_form.lieu).to eq(lieu)
    end
  end

  describe "#to_query" do
    it "return query with lieu" do
      organisation = create(:organisation)
      lieu = create(:lieu, organisation: organisation)

      agent_rdv_search_form = described_class.new(organisation_id: organisation.id, lieu_id: lieu.id)
      expected_query = {
        agent_id: nil,
        start: nil,
        end: nil,
        organisation_id: organisation.id,
        lieu_id: lieu.id,
        show_user_details: nil,
        status: nil,
        user_id: nil
      }
      expect(agent_rdv_search_form.to_query).to eq(expected_query)
    end
  end

  describe "#rdvs" do
    it "call Rdv.with_lieu with given lieu" do
      lieu = create(:lieu)
      agent_rdv_search_form = described_class.new(lieu_id: lieu.id)
      expect(Rdv).to receive(:with_lieu).with(lieu)
      agent_rdv_search_form.rdvs
    end

    it "call Rdv.with_agent with given agent" do
      agent = create(:agent)
      agent_rdv_search_form = described_class.new(agent_id: agent.id)
      expect(Rdv).to receive(:with_agent).with(agent)
      agent_rdv_search_form.rdvs
    end

    it "call Rdv.with_user with given user" do
      user = create(:user)
      agent_rdv_search_form = described_class.new(user_id: user.id)
      expect(Rdv).to receive(:with_user).with(user)
      agent_rdv_search_form.rdvs
    end

    it "return rdvs that starts_at is in window" do
      now = Time.zone.parse("20/07/2019 15:00")
      travel_to(now)
      organisation = create(:organisation)

      users = [build(:user, organisations: [organisation])]
      agents = [build(:agent, organisations: [organisation])]

      rdv1 = create(
        :rdv,
        starts_at: Time.zone.parse("21/07/2019 08:00"),
        organisation: organisation,
        agents: agents,
        users: users
      )
      rdv2 = create(
        :rdv,
        starts_at: Time.zone.parse("21/07/2019 07:00"),
        organisation: organisation,
        agents: agents,
        users: users
      )

      agent_rdv_search_form = described_class.new(
        organisation_id: organisation.id,
        start: Time.zone.parse("20/07/2019 08:00"),
        end: Time.zone.parse("27/07/2019 09:00")
      )

      expect(agent_rdv_search_form.rdvs).to eq([rdv1, rdv2])
    end

    it "return empty when starts_at is outside of window" do
      organisation = create(:organisation)
      now = Time.zone.parse("20/07/2019 15:00")
      travel_to(now)

      create(:rdv, starts_at: Time.zone.parse("21/07/2019 08:00"))
      create(:rdv, starts_at: Time.zone.parse("21/07/2019 07:00"))

      agent_rdv_search_form = described_class.new(
        organisation_id: organisation.id,
        start: Time.zone.parse("10/07/2019 00:00"),
        end: Time.zone.parse("17/07/2019 00:00")
      )

      expect(agent_rdv_search_form.rdvs).to eq([])
    end
  end
end
