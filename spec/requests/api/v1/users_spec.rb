RSpec.describe "/api/v1/users" do
  let(:my_organisation) { create(:organisation) }
  let(:myself) { create(:agent, basic_role_in_organisations: [my_organisation]) }

  let(:headers) do
    oauth_client_headers(oauth_token)
  end
  let(:oauth_token) { create(:access_token, resource_owner_id: myself.id) }

  describe "POST #create" do
    context "simple case, create a user in my org" do
      let(:params) do
        {
          first_name: "Francis",
          last_name: "Factice",
          organisation_ids: [my_organisation.id],
        }
      end

      it "creates the user" do
        expect do
          post "/api/v1/users", headers:, params:, as: :json
        end.to change(User, :count).by(1)
        expect(User.last).to have_attributes(
          first_name: "Francis",
          last_name: "Factice",
          organisations: [my_organisation]
        )
      end

      it "saves whodunnit" do
        post "/api/v1/users", headers:, params:, as: :json
        expect(User.last.versions.last.whodunnit).to eq("[Agent] #{myself.full_name} (id=#{myself.id}) (via API)")
      end
    end

    context "when passing arbitrary organisation_ids outside my orgs" do
      let!(:other_organisation) { create(:organisation) }

      let(:params) do
        {
          first_name: "Francis",
          last_name: "Factice",
          organisation_ids: [other_organisation.id],
        }
      end

      it "creation is forbidden" do
        expect do
          post "/api/v1/users", headers:, params:, as: :json
        end.not_to change(User, :count)
        expect(response.parsed_body["error_messages"].first).to eq("Vous n’avez pas les droits suffisants pour accéder à cette page ou effectuer cette action")
      end
    end

    context "when passing arbitrary referent_agent_ids" do
      let(:agent_from_my_org) { create(:agent, basic_role_in_organisations: [my_organisation]) }
      let(:agent_from_other_org) { create(:agent) }

      let(:params) do
        {
          first_name: "Francis",
          last_name: "Factice",
          organisation_ids: [my_organisation.id],
          referent_agent_ids: [agent_from_other_org.id, myself.id],
        }
      end

      it "agent ids outside my orgs are ignored" do
        post "/api/v1/users", headers:, params:, as: :json
        expect(User.last.referent_agents).to eq([myself])
      end
    end

    describe "external references" do
      let(:params) do
        {
          first_name: "Francis",
          last_name: "Factice",
          organisation_ids: [my_organisation.id],
          external_reference: {
            external_id: "123456",
            external_url: "monsuivisocial.anct.gouv.fr/users/123456",
          },
        }
      end

      it "stores the external reference" do
        post "/api/v1/users", headers:, params:, as: :json
        references = User.last.external_references

        expect(references.count).to eq 1
        expect(references.last).to have_attributes(
          external_id: "123456",
          external_url: "monsuivisocial.anct.gouv.fr/users/123456",
          territory_id: my_organisation.territory.id,
          oauth_application_id: oauth_token.application_id
        )
      end

      context "when another user already exists with this external reference" do
        before do
          ExternalReference.create(
            item: create(:user),
            external_id: "123456",
            external_url: "monsuivisocial.anct.gouv.fr/users/123456",
            territory_id: my_organisation.territory.id,
            oauth_application_id: oauth_token.application_id
          )
        end

        it "doesn't create a new user, and returns an error" do
          expect do
            post "/api/v1/users", headers:, params:, as: :json
          end.not_to change(User, :count)

          expect(parsed_response_body["error_messages"]).to eq ["external_references.external_id est déjà utilisé"]
          expect(response.status).to eq 422
        end
      end
    end
  end

  describe "PUT #update" do
    let(:existing_user) { create(:user, organisations: [my_organisation]) }

    context "simple case, update last name" do
      let(:params) do
        {
          last_name: "Fastoche",
        }
      end

      it "updates successfully" do
        expect do
          put "/api/v1/users/#{existing_user.id}", headers:, params:, as: :json
        end.to change { existing_user.reload.last_name }
        expect(existing_user.reload.last_name).to eq("Fastoche")
      end

      it "does not modify user agent referents" do
        existing_user.referent_agents << myself
        put "/api/v1/users/#{existing_user.id}", headers:, params:, as: :json
        expect(existing_user.reload.referent_agents).to eq([myself])
      end
    end

    context "when passing arbitrary referent_agent_ids" do
      let(:agent_from_other_org) { create(:agent) }

      let(:params) do
        {
          referent_agent_ids: [agent_from_other_org.id, myself.id],
        }
      end

      it "filters out external agents" do
        expect(existing_user.reload.referent_agents).to be_empty
        put "/api/v1/users/#{existing_user.id}", headers:, params:, as: :json
        expect(existing_user.reload.referent_agents).to eq([myself])
      end
    end

    context "quand un usager a un référent auquel je n'ai pas accès en tant qu'agent" do
      let(:agent_from_other_org) { create(:agent) }
      let(:params) do
        {
          referent_agent_ids: [myself.id],
        }
      end

      before do
        existing_user.referent_agents << agent_from_other_org
      end

      it "permet de modifier les référents sans supprimer ceux auxquels je n'ai pas accès" do
        put "/api/v1/users/#{existing_user.id}", headers:, params:, as: :json
        expect(existing_user.reload.referent_agents).to contain_exactly(myself, agent_from_other_org)
      end
    end
  end
end
