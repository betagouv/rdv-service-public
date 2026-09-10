RSpec.describe "API RDV Plan" do
  let(:headers) { oauth_client_headers(oauth_token) }

  let!(:oauth_token) do
    create(:access_token, resource_owner_id: agent.id, application:)
  end
  let(:application) do
    create(:oauth_application,
           name: "Démarches Simplifiées",
           redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback\nhttp://demo.demarches-simplifiees.fr/omniauth/rdvservicepublic/callback",
           post_logout_redirect_uri: "http://localhost:4567/")
  end

  let(:agent) do
    create(:agent, basic_role_in_organisations: [create(:organisation)])
  end

  describe "#create" do
    let(:params) do
      {
        user: {
          first_name: "Francis",
          last_name: "Factice",
        },
      }
    end

    context "quand l'usager n'existe pas encore" do
      it "crée l'usager et le rdv plan" do
        expect do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
        end.to change(User, :count).by(1)
        rdv_plan = RdvPlan.last
        expect(rdv_plan.planning_agent).to eq agent
        expect(rdv_plan.user).to have_attributes(
          first_name: "Francis",
          last_name: "Factice"
        )
      end

      context "quand on réutilise l'id de l'usager pour un second rdv_plan, même si le premier n'a pas été finalisé" do
        before do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
        end

        it "associe aussi l'usager au second rdv plan" do
          first_rdv_plan = RdvPlan.first

          params_for_second_call = { user: { id: first_rdv_plan.user_id } }
          expect do
            post "/api/v1/rdv_plans", headers: headers, params: params_for_second_call, as: :json
          end.to change(RdvPlan, :count).by(1)

          expect(parsed_response_body.dig("rdv_plan", "user_id")).to eq first_rdv_plan.user_id
        end
      end
    end

    context "quand on envoie l'id d'un usager" do
      let(:params) do
        { user: { id: user.id } }
      end

      context "quand l'usager n'est dans aucune des organisations de l'agent" do
        let(:user) do
          create(:user, organisations: [other_organisation])
        end
        let(:other_organisation) { create(:organisation) }

        it "lève une erreur" do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          expect(RdvPlan.last).to be_nil
          expect(response.status).to eq 403
        end
      end

      context "quand l'usager est dans une des organisations de l'agent" do
        let(:user) do
          create(:user, organisations: [agent.organisations.last])
        end

        it "crée le rdv plan avec l'usager" do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          expect(response.status).to eq 201
          expect(User.all.to_a).to eq [user]
          expect(RdvPlan.last.user).to eq user
        end
      end
    end

    context "quand certains paramètres sont manquants" do
      let(:params) do
        { user: { first_name: "Francis" } }
      end

      it "renvoie un message d'erreur et ne crée pas le rdv plan" do
        post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
        expect(RdvPlan.last).to be_nil
        expect(User.last).to be_nil
        expect(response.status).to eq 422
        expect(parsed_response_body["errors"]["last_name"]).to be_present
      end
    end

    context "quand on envoie l'email d'un usager" do
      let(:params) do
        { user: { email: "francis@factice.com", first_name: "Francois", last_name: "Nouveau" } }
      end

      context "quand l'usager existant avec cet email n'est lié à aucune organisation" do
        let!(:user) do
          create(:user, email: "francis@factice.com", phone_number: "0611223344", organisations: [])
        end

        it "crée un nouvel usager au lieu de réutiliser un usager non revendiqué avec lequel l'agent n'a aucun lien" do
          expect do
            post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          end.to change(User, :count).by(1)

          expect(response.status).to eq 201
          new_user = RdvPlan.last.user
          expect(new_user).not_to eq user
          expect(new_user).to have_attributes(email: "francis@factice.com", first_name: "Francois", last_name: "Nouveau", phone_number: nil)
        end

        context "quand l'agent a déjà créé un précédent rdv_plan pour cet usager" do
          before { create(:rdv_plan, planning_agent: agent, user: user) }

          it "réutilise l'usager, puisque l'agent a déjà un lien avec lui" do
            expect do
              post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
            end.not_to change(User, :count)

            expect(response.status).to eq 201
            expect(RdvPlan.last.user).to eq user
          end
        end
      end

      context "quand l'usager existant avec cet email est dans une des organisations de l'agent" do
        let!(:user) do
          create(:user, email: "francis@factice.com", organisations: [agent.organisations.last])
        end

        it "réutilise l'usager existant" do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          expect(response.status).to eq 201
          expect(User.all.to_a).to eq [user]
          expect(RdvPlan.last.user).to eq user
        end

        context "quand l'email est en majuscules" do
          let(:params) do
            { user: { email: "FRANCIS@FACTICE.COM", first_name: "Francois", last_name: "Nouveau" } }
          end

          it "retrouve et réutilise quand même l'usager existant, indépendamment de la casse" do
            post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
            expect(response.status).to eq 201
            expect(User.all.to_a).to eq [user]
            expect(RdvPlan.last.user).to eq user
          end
        end
      end

      context "quand l'usager existant avec cet email appartient à une organisation à laquelle l'agent n'a pas accès" do
        let(:other_organisation) { create(:organisation) }
        let!(:user) do
          create(:user, email: "francis@factice.com", phone_number: "0611223344", organisations: [other_organisation])
        end

        it "crée un nouvel usager au lieu de réutiliser celui auquel l'agent n'a pas accès" do
          expect do
            post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          end.to change(User, :count).by(1)

          expect(response.status).to eq 201
          new_user = RdvPlan.last.user
          expect(new_user).not_to eq user
          expect(new_user).to have_attributes(email: "francis@factice.com", first_name: "Francois", last_name: "Nouveau", phone_number: nil)
        end
      end
    end

    context "quand on envoie tous les paramètres possibles" do
      let(:params) do
        {
          user: {
            first_name: "Francis",
            last_name: "Factice",
            email: "francis@factice.org",
            phone_number: "0611223344",
            address: "21 rue des Ardennes, 75019 Paris",
            birth_date: "1990-12-31",
          },
          return_url: "https://demo.demarches-simplifiees.fr/callback/123",
          dossier_url: "https://demo.demarches-simplifiees.fr/dossier/456",
        }
      end

      it "crée l'usager et le rdv plan avec tous les attributs" do
        expect do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
        end.to change(User, :count).by(1)
        rdv_plan = RdvPlan.last
        expect(rdv_plan).to have_attributes(
          planning_agent: agent,
          return_url: "https://demo.demarches-simplifiees.fr/callback/123",
          dossier_url: "https://demo.demarches-simplifiees.fr/dossier/456",
          oauth_application_id: application.id
        )

        expect(rdv_plan.user).to have_attributes(
          first_name: "Francis",
          last_name: "Factice",
          email: "francis@factice.org",
          phone_number: "0611223344",
          address: "21 rue des Ardennes, 75019 Paris",
          birth_date: Date.parse("1990-12-31")
        )
      end
    end

    context "quand l'agent n'a pas encore configuré d'organisation" do
      let(:agent) { create(:agent, basic_role_in_organisations: []) }

      context "et que l'instance est RDV Service Public" do
        stub_env_with(DEFAULT_DOMAIN_IS_RDV_SOLIDARITES: nil)
        it "affiche une url avec le bon nom de domaine" do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          expect(parsed_response_body.dig("rdv_plan", "url")).to include("www.rdv-service-public-test.localhost")
        end
      end
    end
  end

  describe "#show" do
    context "quand le rdv_plan appartient à un autre usager" do
      let(:rdv_plan) do
        create(:rdv_plan, planning_agent: create(:agent))
      end

      it "renvoie une erreur" do
        get "/api/v1/rdv_plans/#{rdv_plan.id}", headers: headers, params: {}, as: :json
        expect(response.status).to eq 404
      end
    end

    describe "utilise la bonne timezone" do
      let(:organisation) { create(:organisation, time_zone: "America/Guadeloupe") }
      let(:rdv) { create(:rdv, organisation: organisation) }
      let(:rdv_plan) { create(:rdv_plan, planning_agent: agent, rdv: rdv) }

      context "lorsque la timezone de l'organisation est la timezone par défaut (Europe/Paris)" do
        let(:organisation) { create(:organisation) }

        it "utilise la timezone de l'instance" do
          get "/api/v1/rdv_plans/#{rdv_plan.id}", headers: headers, params: {}, as: :json
          expect(parsed_response_body.dig("rdv_plan", "rdv", "starts_at")).to eq rdv.starts_at.to_s
        end
      end

      context "lorsque la timezone de l'organisation est définie" do
        let(:rdv) { create(:rdv, organisation: organisation, starts_at: Time.zone.parse("2025-01-15 10:00:00")) }

        it "utilise la timezone de l'organisation" do
          get "/api/v1/rdv_plans/#{rdv_plan.id}", headers: headers, params: {}, as: :json
          expect(parsed_response_body.dig("rdv_plan", "rdv", "starts_at")).to eq "2025-01-15 10:00:00 -0400"
        end
      end
    end
  end
end
