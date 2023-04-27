# frozen_string_literal: true

require "swagger_helper"

describe "Absence authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/absences" do
    get "Lister les absences" do
      with_authentication
      with_pagination

      tags "Absence"
      produces "application/json"
      operationId "getAbsences"
      description "Renvoie les absences des agents de mes organisations, de manière paginée"

      let!(:organisation1) { create(:organisation) }
      let!(:organisation2) { create(:organisation) }
      let!(:organisation3) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation1, organisation2]) }
      let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation1], service: agent.service) }
      let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation2]) }
      let!(:agent3) { create(:agent, basic_role_in_organisations: [organisation3]) }
      let!(:absence1) { create(:absence, agent: agent1) }
      let!(:absence2) { create(:absence, agent: agent2) }
      let!(:absence3) { create(:absence, agent: agent3) }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Renvoie les absences des organisations auxquelles l'agent.e a accès", document: false do
        schema "$ref" => "#/components/schemas/absences"

        run_test!

        it { expect(parsed_response_body["absences"].pluck("id")).to match_array([absence1.id]) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"
    end

    post "Créer une absence" do
      with_authentication

      tags "Absence"
      produces "application/json"
      operationId "createAbsence"
      description "Crée une absence"

      parameter name: "agent_id", in: :query, type: :integer, description: "ID de l'agent", example: 23, required: false
      parameter name: "agent_email", in: :query, type: :string, description: "Email de l'agent", example: "agent@example.com", required: false
      parameter name: "title", in: :query, type: :string, description: "Titre de l'absence", example: "Super absence"
      parameter name: "first_day", in: :query, type: :string, description: "Premier jour de l'absence", example: "2023-11-20"
      parameter name: "start_time", in: :query, type: :string, description: "Heure de début de l'absence", example: "08:00"
      parameter name: "end_day", in: :query, type: :string, description: "Dernier jour de l'absence", example: "2023-11-20"
      parameter name: "end_time", in: :query, type: :string, description: "Heure de fin de l'absence", example: "15:00"

      let(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, id: 12, email: "agent@example.com", basic_role_in_organisations: [organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Crée et renvoie une absence" do
        let(:agent_id) { 12 }
        let(:title) { "Super absence" }
        let(:first_day) { "2023-11-20" }
        let(:start_time) { "08:00" }
        let(:end_day) { "2023-11-20" }
        let(:end_time) { "15:00" }

        let!(:absence_count_before) { Absence.count }
        let(:created_absence) { Absence.find(parsed_response_body["absence"]["id"]) }

        schema "$ref" => "#/components/schemas/absence_with_root"

        run_test!

        it { expect(Absence.count).to eq(absence_count_before + 1) }

        it { expect(created_absence.agent).to eq(agent) }

        it { expect(created_absence.title).to eq(title) }

        it { expect(created_absence.first_day).to eq(Date.new(2023, 11, 20)) }

        it { expect(created_absence.start_time).to eq(Tod::TimeOfDay.new(8, 0)) }

        it { expect(created_absence.end_day).to eq(Date.new(2023, 11, 20)) }

        it { expect(created_absence.end_time).to eq(Tod::TimeOfDay.new(15, 0)) }
      end

      response 200, "Crée et renvoie une absence quand c'est l'email de l'agent qu'on utilise", document: false do
        let(:agent_email) { "agent@example.com" }
        let(:title) { "Super absence" }
        let(:first_day) { "2023-11-20" }
        let(:start_time) { "08:00" }
        let(:end_day) { "2023-11-20" }
        let(:end_time) { "15:00" }

        let!(:absence_count_before) { Absence.count }
        let(:created_absence) { Absence.find(parsed_response_body["absence"]["id"]) }

        schema "$ref" => "#/components/schemas/absence_with_root"

        run_test!

        it { expect(Absence.count).to eq(absence_count_before + 1) }
        it { expect(created_absence.agent).to eq(agent) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let(:title) { "Super absence" }
        let(:first_day) { "2023-11-20" }
        let(:start_time) { "08:00" }
        let(:end_day) { "2023-11-20" }
        let(:end_time) { "15:00" }
      end

      it_behaves_like "an endpoint that returns 404 - not found", "l'agent.e est introuvable" do
        let(:agent_email) { "test@example.com" }
        let(:title) { "Super absence" }
        let(:first_day) { "2023-11-20" }
        let(:start_time) { "08:00" }
        let(:end_day) { "2023-11-20" }
        let(:end_time) { "15:00" }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "quand end_time est avant start_time ou que les formats ne sont pas corrects", true do
        let(:agent_email) { "agent@example.com" }
        let(:title) { "Super absence" }
        let(:first_day) { "2023-11-20" }
        let(:start_time) { "08:00" }
        let(:end_day) { "2023-11-20" }
        let(:end_time) { "06:00" }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "le format du start_time ou end_time n'est pas correct", false do
        let(:agent_email) { "agent@example.com" }
        let(:title) { "Super absence" }
        let(:first_day) { "2023-11-20" }
        let(:start_time) { "8h" }
        let(:end_day) { "2023-11-20" }
        let(:end_time) { "15:00" }
      end

      context "Crée une absence pour un.e agent.e dans un service différent de mon organisation" do
        let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation], service: create(:service), email: "another@example.com") }
        let(:agent_email) { "another@example.com" }
        let(:title) { "Super absence" }
        let(:first_day) { "2023-11-20" }
        let(:start_time) { "08:00" }
        let(:end_day) { "2023-11-20" }
        let(:end_time) { "15:00" }

        let!(:absence_count_before) { Absence.count }

        it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent·e est dans un service différent" do
          let!(:agent) { create(:agent, service: create(:service)) }
          let!(:agent_role) { create(:agent_role, agent: agent, level: AgentRole::LEVEL_BASIC, organisation: organisation) }
        end

        response 200, "Possible si l'agent est admin", document: false do
          let!(:agent) { create(:agent, service: create(:service)) }
          let!(:agent_role) { create(:agent_role, agent: agent, level: AgentRole::LEVEL_ADMIN, organisation: organisation) }

          let(:created_absence) { Absence.find(parsed_response_body["absence"]["id"]) }

          schema "$ref" => "#/components/schemas/absence_with_root"

          run_test!

          it { expect(Absence.count).to eq(absence_count_before + 1) }
          it { expect(created_absence.agent).to eq(agent2) }
        end
      end
    end
  end

  path "/api/v1/absences/{absence_id}" do
    get "Récupérer une absence" do
      with_authentication

      tags "Absence"
      produces "application/json"
      operationId "getAbsence"
      description "Renvoie une absence"

      parameter name: "absence_id", in: :path, type: :string, description: "L'ID d'une absence donnée", example: "12"

      let!(:agent) { create(:agent, :with_basic_org) }
      let!(:agent2) { create(:agent, :with_basic_org) }
      let!(:absence1) { create(:absence, agent: agent) }
      let!(:absence2) { create(:absence, agent: agent2) }
      let(:absence_id) { absence1.id }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Renvoie l'absence" do
        schema "$ref" => "#/components/schemas/absence_with_root"

        run_test!

        it { expect(parsed_response_body[:absence][:id]).to eq(absence1.id) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent·e n'est pas autorisé·e à accéder à cette absence" do
        let(:absence_id) { absence2.id }
      end

      it_behaves_like "an endpoint that returns 404 - not found", "l'absence n'existe pas" do
        let(:absence_id) { "inconnue" }
      end
    end

    patch "Modifier une absence" do
      with_authentication

      tags "Absence"
      produces "application/json"
      operationId "updateAbsence"
      description "Modifie une absence"

      parameter name: "absence_id", in: :path, type: :string, description: "L'ID d'une absence donnée", example: "12"

      parameter name: "title", in: :query, type: :string, description: "Titre de l'absence", example: "Super absence", required: false
      parameter name: "first_day", in: :query, type: :string, description: "Premier jour de l'absence", example: "2023-11-20", required: false
      parameter name: "start_time", in: :query, type: :string, description: "Heure de début de l'absence", example: "08:00", required: false
      parameter name: "end_day", in: :query, type: :string, description: "Dernier jour de l'absence", example: "2023-11-20", required: false
      parameter name: "end_time", in: :query, type: :string, description: "Heure de fin de l'absence", example: "15:00", required: false

      let!(:agent) { create(:agent, :with_basic_org) }
      let!(:agent2) { create(:agent, :with_basic_org) }
      let!(:absence1) { create(:absence, agent: agent, title: "Titre 1") }
      let!(:absence2) { create(:absence, agent: agent2, title: "Titre 2") }
      let(:absence_id) { absence1.id }
      let(:title) { "Nouveau titre" }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Modifie et renvoie l'absence" do
        schema "$ref" => "#/components/schemas/absence_with_root"

        run_test!

        it { expect(parsed_response_body[:absence][:id]).to eq(absence1.id) }

        it { expect(absence1.reload.title).to eq("Nouveau titre") }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent·e n'est pas autorisé·e à accéder à cette absence" do
        let(:absence_id) { absence2.id }
      end

      it_behaves_like "an endpoint that returns 404 - not found", "l'absence n'existe pas" do
        let(:absence_id) { "inconnue" }
      end
    end

    delete "Détruire une absence" do
      with_authentication

      tags "Absence"
      produces "application/json"
      operationId "deleteAbsence"
      description "Détruit une absence"

      parameter name: "absence_id", in: :path, type: :string, description: "L'ID d'une absence donnée", example: "12"

      let!(:agent) { create(:agent, :with_basic_org) }
      let!(:agent2) { create(:agent, :with_basic_org) }
      let!(:absence1) { create(:absence, agent: agent) }
      let!(:absence2) { create(:absence, agent: agent2) }
      let(:absence_id) { absence1.id }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 204, "Détruit l'absence" do
        let!(:absence_count_before) { Absence.count }

        run_test!

        it { expect(Absence.count).to eq(absence_count_before - 1) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent·e n'est pas autorisé·e à accéder à cette absence" do
        let(:absence_id) { absence2.id }
      end

      it_behaves_like "an endpoint that returns 404 - not found", "l'absence n'existe pas" do
        let(:absence_id) { "inconnue" }
      end
    end
  end
end
