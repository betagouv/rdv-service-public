RSpec.describe "RedirectController#reprendre_rdv_from_participation_invitation_token", type: :request do
  describe "GET /prdv" do
    context "avec un token de participation valide" do
      let(:organisation) { create(:organisation) }
      let(:motif) { create(:motif, organisation:) }
      let(:lieu) { create(:lieu, organisation:) }
      let(:rdv) { create(:rdv, organisation:, motif:, lieu:) }
      let(:token) { rdv.participations.first.restricted_auth_token }

      it "redirige vers la recherche scopée à l'organisation, au lieu et au motif du RDV" do
        get "/prdv", params: { tkn: token }

        expect(response).to redirect_to(
          prendre_rdv_path(
            departement: organisation.departement_number,
            preselected_motif: motif.public_link_id,
            public_link_organisation_id: organisation.id,
            lieu_id: lieu.id,
            invitation_token: token
          )
        )
      end
    end

    context "avec un token inconnu" do
      it "redirige vers l'accueil avec un message d'erreur" do
        get "/prdv", params: { tkn: "token-inconnu" }

        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq(I18n.t("devise.invitations.invitation_token_invalid"))
      end
    end

    it "ne divulgue pas l'adresse personnelle du bénéficiaire d'un RDV à domicile dans la redirection" do
      organisation = create(:organisation)
      motif = create(:motif, :at_home, organisation:, bookable_by: :everyone)
      user = create(:user, address: "12 rue Secrète, 75001 Paris")
      rdv = create(:rdv, organisation:, motif:, lieu: nil, users: [user])
      token = rdv.participations.first.restricted_auth_token

      get "/prdv", params: { tkn: token }

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).not_to include("Secr")
      expect(response.headers["Location"]).not_to include(CGI.escape("12 rue Secrète, 75001 Paris"))
    end
  end
end
