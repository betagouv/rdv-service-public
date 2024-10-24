RSpec.describe Admin::Agenda::RdvsController, type: :controller do
  render_views

  # Semaine du lundi 8 avril 2024 au vendredi 12 avril 2024.
  # On note que FullCalendar utilise des dates naïves (sans timezone).
  let(:fullcalendar_time_range_params) do
    {
      start: "2024-04-08T00:00:00",
      end: "2024-04-13T00:00:00", # FullCalendar utilise cette valeur pour indiquer "jusqu'au vendredi 12 inclus"
    }
  end
  let(:aujourdhui_lundi_15h) { Time.zone.parse("2024-04-08 15:00:00") }
  let(:mercredi_15h) { Time.zone.parse("2024-04-10 15:00:00") }

  let(:organisation) { create(:organisation) }

  before { sign_in current_agent }

  describe "displaying RDVs across organisations" do
    let(:other_organisation) { create(:organisation) }
    let(:current_agent) { create(:agent, admin_role_in_organisations: [organisation, other_organisation]) }

    it "returns rdvs of given agent across organisations" do
      travel_to(aujourdhui_lundi_15h)
      given_agent = create(:agent, basic_role_in_organisations: [organisation], service: current_agent.services.first)
      create(:rdv, agents: [current_agent])
      rdv = create(:rdv, agents: [given_agent], organisation: organisation, starts_at: mercredi_15h)
      rdv_from_other_organisation = create(:rdv, agents: [given_agent], organisation: other_organisation, starts_at: mercredi_15h)
      get :index, params: fullcalendar_time_range_params.merge(agent_id: given_agent.id, organisation_id: organisation.id, format: :json)
      expect(response).to be_successful

      returns_rdvs = response.parsed_body
      expect(returns_rdvs.pluck("id")).to contain_exactly(rdv.id, rdv_from_other_organisation.id)

      # Les RDVs des autres orgas sont affichés en gris
      expect(returns_rdvs.find { _1["id"] == rdv_from_other_organisation.id }["backgroundColor"]).to eq("#757575")
    end
  end

  describe "respecting the time range" do
    let(:samedi_15h) { Time.zone.parse("2024-04-13 15:00:00") }
    let(:mardi_en_huit_15h) { Time.zone.parse("2024-04-16 15:00:00") }
    let(:vendredi_dernier_15h) { Time.zone.parse("2024-04-05 15:00:00") }

    let(:current_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    it "returns rdvs of given agent from start to end" do
      travel_to(aujourdhui_lundi_15h)
      create(:rdv, agents: [current_agent], organisation: organisation, starts_at: vendredi_dernier_15h)
      rdv = create(:rdv, agents: [current_agent], organisation: organisation, starts_at: mercredi_15h)
      create(:rdv, agents: [current_agent], organisation: organisation, starts_at: samedi_15h)
      create(:rdv, agents: [current_agent], organisation: organisation, starts_at: mardi_en_huit_15h)

      get :index, params: fullcalendar_time_range_params.merge(agent_id: current_agent.id, organisation_id: organisation.id, format: :json)
      expect(response.parsed_body.pluck("id")).to eq([rdv.id])
    end
  end

  describe "showing RDVs without details" do
    describe "showing an agent's RDVs for a service in which I am not" do
      let(:current_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      it "does not show any info about the RDV and does not provide a link" do
        other_service = create(:service)
        given_agent = create(:agent, basic_role_in_organisations: [organisation], service: current_agent.services.first)
        rdv_of_another_service = create(:rdv, agents: [given_agent], organisation: organisation, starts_at: mercredi_15h, motif: create(:motif, service: other_service))
        get :index, params: fullcalendar_time_range_params.merge(agent_id: given_agent.id, organisation_id: organisation.id, format: :json)
        expect(response.parsed_body.size).to eq(1)
        expect(response.parsed_body[0].keys).to eq(%w[start end title textColor backgroundColor extendedProps])
        expect(response.parsed_body[0]["title"]).to eq("Occupé⋅e (en RDV)")
        expect(Time.zone.parse(response.parsed_body[0]["start"])).to eq(rdv_of_another_service.starts_at)
        expect(Time.zone.parse(response.parsed_body[0]["end"])).to eq(rdv_of_another_service.ends_at)
        expect(response.parsed_body[0]["extendedProps"]["unauthorizedRdvExplanation"]).to include("Vous ne pouvez pas voir ce RDV")
      end
    end

    describe "showing an agent's RDVs for an organisation where I don't belongs" do
      let(:current_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      it "does not show any info about the RDV and does not provide a link" do
        other_org = create(:organisation)
        given_agent = create(:agent, basic_role_in_organisations: [organisation, other_org], service: current_agent.services.first)
        motif_of_other_org = create(:motif, organisation: other_org, service: current_agent.services.first)
        rdv_of_another_org_same_service = create(:rdv, agents: [given_agent], organisation: other_org, starts_at: aujourdhui_lundi_15h, motif: motif_of_other_org)
        get :index, params: fullcalendar_time_range_params.merge(agent_id: given_agent.id, organisation_id: organisation.id, format: :json)
        expect(response.parsed_body.size).to eq(1)
        expect(response.parsed_body[0].keys).to eq(%w[start end title textColor backgroundColor extendedProps])
        expect(response.parsed_body[0]["title"]).to eq("Occupé⋅e (en RDV)")
        expect(Time.zone.parse(response.parsed_body[0]["start"])).to eq(rdv_of_another_org_same_service.starts_at)
        expect(Time.zone.parse(response.parsed_body[0]["end"])).to eq(rdv_of_another_org_same_service.ends_at)
        expect(response.parsed_body[0]["extendedProps"]["unauthorizedRdvExplanation"]).to include("Vous ne pouvez pas voir ce RDV")
      end
    end
  end
end
