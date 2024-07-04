RSpec.describe Agents::UsersController, "#search" do
  let!(:territory) { create(:territory) }
  let!(:organisation_of_agent) { create(:organisation, territory: territory) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation_of_agent]) }

  describe "results for users outside of the given organisation" do
    let!(:other_organisation) { create(:organisation, territory: territory) }
    let!(:user_in_org) do
      create(:user, organisations: [organisation_of_agent], first_name: "Marion", last_name: "Delorga",
                    birth_date: "1990-01-01", phone_number: "0611223344", email: "marion@example.com")
    end
    let!(:user_in_territory) do
      create(:user, organisations: [other_organisation], first_name: "Marine", last_name: "Duterritoire",
                    birth_date: "1990-01-01", phone_number: "0611223344", email: "marine@example.com")
    end

    it "includes users of other orgs, truncated" do
      sign_in agent
      get search_agents_users_path(organisation_id: organisation_of_agent, term: "mari")

      expect(parsed_response_body[:results].size).to eq(2)
      expect(response.body).to include("DELORGA Marion - 01/01/1990 - 06 11 22 33 44 - marion@example.com")
      expect(response.body).to include("DUTERRITOIRE Marine - 01/01/**** - 06******44 - m******e@example.com")
    end

    context "when in CN territory" do
      let(:territory) { create(:territory, departement_number: Territory::CN_DEPARTEMENT_NUMBER) }

      it "does not include users from other orgs in the territory" do
        sign_in agent
        get search_agents_users_path(organisation_id: organisation_of_agent, term: "mari")

        expect(parsed_response_body[:results].size).to eq(1)
        expect(response.body).to include("DELORGA Marion - 01/01/1990 - 06 11 22 33 44 - marion@example.com")
        expect(response.body).not_to include("DUTERRITOIRE")
      end
    end
  end

  context "when passing an organisation_id the agent doesn't belong to" do
    let(:other_organisation) { create(:organisation, territory: territory) }

    it "redirects with a flash message" do
      sign_in agent
      get search_agents_users_path(organisation_id: other_organisation)
      expect(response).to have_http_status(:found) # 302 redirects
      expect(flash[:error]).to eq("Vous ne pouvez pas accéder à cette organisation")
    end
  end
end
