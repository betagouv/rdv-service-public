RSpec.describe "demandes supports", type: :request do
  describe "#new" do
    specify do
      get new_aide_demande_support_path
      expect(response).to be_successful
      expect(response.body).to include("Formulaire de contact")
    end
  end

  describe "#create" do
    include_context "enable rack-attack" # en l’activant ici on teste que le cas normal fonctionne aussi

    context "paramètres valides pour un usager" do
      let(:params) do
        {
          demande_support_form: {
            role: "usager",
            sujet: "Test",
            email: "jesuis@perdue.fr",
            first_name: "Anna",
            last_name: "Klaros",
            message: "Je suis super duper",
          },
        }
      end

      specify do
        post(aide_demande_support_path, params:)
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Votre demande de support a bien été envoyée")
      end

      context "tentatives d’innondations" do
        specify do
          2.times do
            post(aide_demande_support_path, params:)
            expect(response).to redirect_to(root_path)
          end
          post(aide_demande_support_path, params:)
          expect(response.status).to eq(429)
        end
      end
    end
  end
end
