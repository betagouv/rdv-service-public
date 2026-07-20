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
            motif_name_with_location_type: motif.name_with_location_type,
            public_link_organisation_id: organisation.id,
            lieu_id: lieu.id,
            address: rdv.address,
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
  end
end
