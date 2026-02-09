RSpec.describe "RDV API" do
  let!(:oauth_token) do
    create(:access_token, resource_owner_id: agent.id, application:)
  end
  let(:headers) do
    {
      "Content-Type": "application/json",
      Authorization: "Bearer #{oauth_token.plaintext_token}",
    }
  end
  let(:application) { create(:oauth_application) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let(:organisation) { create(:organisation) }
  let(:service) { create(:service) }

  describe "#index" do
    let(:motif) { create(:motif, organisation: organisation, service: service) }

    let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    let!(:rdv_with_user_and_agent) { create(:rdv, organisation: organisation, motif: motif, users: [user], agents: [agent]) }
    let!(:rdv_with_user_and_other_agent) { create(:rdv, organisation: organisation, motif: motif, users: [user], agents: [other_agent]) }

    let!(:rdv_with_other_user_and_agent) { create(:rdv, organisation: organisation, motif: motif, users: [other_user], agents: [agent]) }
    let!(:rdv_with_other_user_and_other_agent) { create(:rdv, organisation: organisation, motif: motif, users: [other_user], agents: [other_agent]) }

    let!(:cancelled_rdv) { create(:rdv, organisation:, motif:, agents: [agent], status: :excused) }

    it "filters by agent and user id" do
      get "/api/v1/rdvs", headers: headers, params: { user_id: user.id, agent_id: agent.id }, as: :json
      expect(parsed_response_body["rdvs"].count).to eq 1
      expect(parsed_response_body["rdvs"].first["id"]).to eq rdv_with_user_and_agent.id
    end

    it "allows filtering by agent and restricting the included fields" do
      get "/api/v1/rdvs", headers: headers, params: { agent_id: agent.id, include: [:agents] }, as: :json
      expect(parsed_response_body["rdvs"].count).to eq 3
    end

    it "allows filtering by agent even if they are not in the included fields" do
      get "/api/v1/rdvs", headers: headers, params: { agent_id: agent.id, include: [:motif] }, as: :json
      expect(parsed_response_body["rdvs"].count).to eq 3
    end

    it "filters by id when passing an array" do
      get "/api/v1/rdvs", headers: headers, params: { id: [rdv_with_user_and_other_agent.id, rdv_with_other_user_and_agent.id] }, as: :json
      expect(parsed_response_body["rdvs"].count).to eq 2

      response_ids = [
        parsed_response_body["rdvs"].first["id"],
        parsed_response_body["rdvs"].second["id"],
      ]

      expect(response_ids).to contain_exactly(rdv_with_user_and_other_agent.id, rdv_with_other_user_and_agent.id)
    end

    it "filters by id with only one value" do
      get "/api/v1/rdvs", headers: headers, params: { id: rdv_with_user_and_agent.id }, as: :json
      expect(parsed_response_body["rdvs"].count).to eq 1
      expect(parsed_response_body["rdvs"].first["id"]).to eq rdv_with_user_and_agent.id
    end

    it "filters by statuses" do
      get "/api/v1/rdvs", headers: headers, params: { status: "excused" }, as: :json

      expect(parsed_response_body["rdvs"].count).to eq 1
      expect(parsed_response_body["rdvs"].first["id"]).to eq cancelled_rdv.id
    end

    describe "selecting which associations are loaded" do
      it "makes the api response smaller" do
        get "/api/v1/rdvs", headers: headers, params: { include: %w[lieu motif agents] }
        rdv = parsed_response_body["rdvs"].first

        expect(rdv["agents"]).to be_present
        expect(rdv["lieu"]).to be_present
        expect(rdv["motif"]).to be_present

        expect(rdv).not_to have_key("organisation")
        expect(rdv).not_to have_key("users")
        expect(rdv).not_to have_key("participations")
      end

      it "supports a comma separated string syntax" do
        get "/api/v1/rdvs", headers: headers, params: { include: "lieu,motif,agents" }
        rdv = parsed_response_body["rdvs"].first

        expect(rdv["agents"]).to be_present
        expect(rdv["lieu"]).to be_present
        expect(rdv["motif"]).to be_present

        expect(rdv).not_to have_key("organisation")
        expect(rdv).not_to have_key("users")
        expect(rdv).not_to have_key("participations")
      end

      it "also works when filtering by user_id" do
        get "/api/v1/rdvs", headers: headers, params: { include: %w[lieu motif agents], user_id: user.id }

        rdv = parsed_response_body["rdvs"].first
        expect(rdv["agents"]).to be_present
        expect(rdv).not_to have_key("organisation")
      end
    end
  end

  describe "#create" do
    context "pour une migration inter-instance d'un rendez-vous pris par un usager" do
      let(:user_on_old_instance) { create(:user, organisations: [organisation_on_old_instance]) }
      let!(:rdv_on_old_instance) do
        create(:rdv, agents: [agent_on_old_instance], motif: motif_on_old_instance,
                     users: [user_on_old_instance], starts_at: 2.weeks.ago, created_by: user_on_old_instance,
                     lieu: lieu_on_old_instance, organisation: instance_export.source_organisation)
      end

      let(:motif_on_old_instance) { create(:motif, organisation: organisation_on_old_instance) }

      let(:lieu_on_old_instance) { create(:lieu, organisation: organisation_on_old_instance) }

      let(:agent_on_old_instance) { agent } # La contrainte d'unicité sur agents.email et le fait que l'email soit utilisé des les params de la requête nous oblige à réutiliser le même agent ici

      let(:organisation_on_old_instance) { create(:organisation) }
      let(:instance_export) { create(:instance_export, source_organisation: organisation_on_old_instance, agent: agent_on_old_instance) }

      # On crée les données qui auraient été créées par les premiers jobs
      let(:motif_on_new_instance) { create(:motif, organisation:, service: service) }
      let!(:motif_external_reference) { create(:external_reference, item: motif_on_new_instance, external_id: motif_on_old_instance.id, oauth_application: application) }

      let(:lieu_on_new_instance) { create(:lieu, organisation:) }
      let!(:lieu_external_reference) { create(:external_reference, item: lieu_on_new_instance, external_id: lieu_on_old_instance.id, oauth_application: application) }

      let(:user_on_new_instance) { create(:user, organisations: [organisation]) }
      let!(:user_external_reference) { create(:external_reference, item: user_on_new_instance, external_id: user_on_old_instance.id, oauth_application: application) }

      let(:request_params) do
        request_params = nil
        allow_any_instance_of(RdvServicePublicApiClient).to receive(:post) do |_object, _path, params| # rubocop:disable RSpec/AnyInstance
          request_params = params
        end

        # On démarre le test depuis le job qui fait la synchronisation pour vérifier que la sérialisation marche bien avec le controller
        # On exécute le job afin que sa requête API soit enregistrée dans request_params par le block ci-dessus.
        InstanceExports::CopyPlanningJob::CopyRdvJob.new.perform(instance_export.id, rdv_on_old_instance.id, Domain::RDV_AIDE_NUMERIQUE.id)
        request_params
      end

      it "sends all the information to the new instance" do
        expect do
          post "/api/v1/rdvs", headers:, params: request_params, as: :json
        end.to change(Rdv, :count).by(1)

        expect(Rdv.last.created_by).to eq user_on_new_instance
      end

      context "quand l'agent du rendez-vous a été supprimé" do
        let(:other_agent_on_old_instance) { create(:agent, basic_role_in_organisations: [instance_export.source_organisation]) }

        let!(:rdv_on_old_instance) do
          create(:rdv, agents: [other_agent_on_old_instance], motif: motif_on_old_instance,
                       users: [user_on_old_instance], starts_at: 2.weeks.ago, created_by: user_on_old_instance,
                       lieu: lieu_on_old_instance, organisation: instance_export.source_organisation)
        end

        before do
          AgentRemoval.new(other_agent_on_old_instance, instance_export.source_organisation).remove!
        end

        it "essaye de créer le rendez-vous" do
          # On génère la requête, puis on supprime les données pour simuler le fait d'être sur une autre instance
          params = request_params

          rdv_on_old_instance.destroy
          other_agent_on_old_instance.delete

          expect { post("/api/v1/rdvs", headers:, params:, as: :json) }.to change(Rdv, :count).by(1)

          expect(Rdv.last.created_by).to eq user_on_new_instance
        end
      end
    end

    it "returns a JSON response and warns sentry in case of unexpected error" do
      allow(Rdv).to receive(:new).and_raise("boom")
      post "/api/v1/rdvs", headers:, params: {}, as: :json

      expect(response.parsed_body["errors"]).to include("Unexpected internal error")
      expect(sentry_events.last.exception.values.first.value).to eq("boom (RuntimeError)")
    end
  end
end
