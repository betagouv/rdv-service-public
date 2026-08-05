RSpec.describe "Search", type: :request do
  include Rails.application.routes.url_helpers

  describe "GET /" do
    context "without params" do
      it "is successful" do
        get "http://www.rdv-solidarites-test.localhost/"
        expect(response).to be_successful
      end

      it "render adress_selection template" do
        get "http://www.rdv-solidarites-test.localhost/"
        expect(response).to render_template("search/address_selection/_rdv_solidarites")
      end
    end

    context "with connected user" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, organisations: [organisation]) }
      let(:user) { create(:user, organisations: [organisation], referent_agents: [agent]) }

      before do
        login_as(user, scope: :user)
      end

      context "with agent_id params" do
        it "render motif_selection template" do
          motif = create(:motif, follow_up: true, organisation: organisation)
          create(:plage_ouverture, agent: agent, motifs: [motif], organisation: organisation)
          get prendre_rdv_url(referent_ids: [agent.id], departement: organisation.territory.departement_number, host: "www.rdv-solidarites-test.localhost")
          expect(response).to render_template("search/_motif_selection")
        end
      end
    end

    context "service selection" do
      let(:territory) { create(:territory, departement_number: "75") }
      let(:organisation) { create(:organisation, territory: territory) }
      let(:motif) { create(:motif, organisation: organisation) }
      let(:other_motif) { create(:motif, organisation: organisation) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif, other_motif], organisation: organisation) }

      context "lorsqu’il n’y a pas de motif de suivi associé aux services" do
        it "n’affiche pas l’invitation à se connecter pour prendre un RDV de suivi" do
          get root_url(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001", host: "www.rdv-solidarites-test.localhost")
          expect(response.body).not_to include("Pour prendre un RDV de suivi avec un de vos agents référents")
        end
      end

      context "lorsqu’il y a un motif de suivi associé aux services" do
        let(:bookable_by) { :everyone }
        let!(:follow_up_motif) { create(:motif, organisation: organisation, service: motif.service, follow_up: true, bookable_by:) }

        it "affiche l’invitation à se connecter pour prendre un RDV de suivi" do
          get root_url(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001", host: "www.rdv-solidarites-test.localhost")
          expect(response.body).to include("Pour prendre un RDV de suivi avec un de vos agents référents")
        end

        context "lorsque le motif est réservable que par un agent" do
          let(:bookable_by) { :agents }

          it "n’affiche pas l’invitation à se connecter" do
            get root_url(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001", host: "www.rdv-solidarites-test.localhost")
            expect(response.body).not_to include("Pour prendre un RDV de suivi avec un de vos agents référents")
          end
        end
      end
    end

    context "motif selection" do
      let(:territory) { create(:territory, departement_number: "75") }
      let(:organisation) { create(:organisation, territory: territory) }
      let(:motif) { create(:motif, organisation: organisation) }
      let(:other_motif) { create(:motif, organisation: organisation, service: motif.service) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif, other_motif], organisation: organisation) }

      context "lorsqu’il n’y a pas de motif de suivi associé aux services" do
        it "n’affiche pas l’invitation à se connecter" do
          get root_url(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001", host: "www.rdv-solidarites-test.localhost")
          expect(response.body).not_to include("Pour prendre un RDV de suivi avec un de vos agents référents")
        end
      end

      context "lorsqu’il y a un motif de suivi associé aux services" do
        let(:bookable_by) { :everyone }
        let!(:follow_up_motif) { create(:motif, organisation: organisation, service: motif.service, follow_up: true, bookable_by:) }

        it "affiche l’invitation à se connecter pour prendre un RDV de suivi" do
          get root_url(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001", host: "www.rdv-solidarites-test.localhost")
          expect(response.body).to include("Pour prendre un RDV de suivi avec un de vos agents référents")
        end

        context "lorsque le motif est réservable que par un agent" do
          let(:bookable_by) { :agents }

          it "n’affiche pas l’invitation à se connecter" do
            get root_url(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001", host: "www.rdv-solidarites-test.localhost")
            expect(response.body).not_to include("Pour prendre un RDV de suivi avec un de vos agents référents")
          end
        end
      end
    end
  end

  describe "GET /prendre_rdv" do
    it "is successful" do
      get "http://www.rdv-solidarites-test.localhost/prendre_rdv"
      expect(response).to be_successful
    end
  end

  describe "GET /prendre_rdv sur les domaines sans recherche géographique" do
    [
      "www.rdv-service-public-test.localhost",
      "www.rdv-service-public-etat-test.localhost",
    ].each do |host|
      context "sur #{host}" do
        it "redirige vers l'accueil si le paramètre departement est fourni" do
          get prendre_rdv_url(host:, departement: "75")
          expect(response).to redirect_to(root_url(host:))
        end

        it "redirige vers l'accueil si tous les paramètres de recherche géo sont fournis" do
          get prendre_rdv_url(host:, departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
          expect(response).to redirect_to(root_url(host:))
        end

        it "redirige vers l'accueil si des paramètres géo sans departement sont fournis" do
          get prendre_rdv_url(host:, latitude: "48.859", longitude: "2.347")
          expect(response).to redirect_to(root_url(host:))
        end
      end
    end
  end

  # dans le le CDAD de la Côte d'Or,  les agents ont distribué un lien de prise de rendez-vous à
  # l'échelle de leur espace. Pour éviter de casser ce lien, et en attendant d'avoir une solution plus pérenne,
  # on autorise l'utilisation du paramètre departement dans ce cas.
  # Leur nom de département étant C21, il n'y a pas de risque de permettre de scraper d'autres territoires.
  it "marche pour le lien du CDAD de la Côte d'Or" do
    get prendre_rdv_url(host: "www.rdv-service-public-test.localhost", departement: "C21")
    expect(response).to be_successful
  end
end
