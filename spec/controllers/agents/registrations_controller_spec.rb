RSpec.describe Agents::RegistrationsController do
  let(:agent) { create(:agent) }

  before do
    request.env["devise.mapping"] = Devise.mappings[:agent] # d'après la doc de Devise
    sign_in agent
  end

  describe "#destroy" do
    it "supprime le compte et affiche le message de confirmation" do
      delete :destroy

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq(I18n.t("devise.failure.deleted_account"))
    end

    it "vide la session dans son intégralité" do
      session[:some_unrelated_key] = "devrait disparaître"
      delete :destroy
      expect(session[:some_unrelated_key]).to be_nil
    end

    context "quand l'agent est usurpé par un super admin" do
      let(:super_admin) { create(:super_admin) }

      before do
        sign_in super_admin, scope: :super_admin
        session[:super_admin_signed_in_as_agent] = true
        session[:some_unrelated_key] = "devrait survivre"
      end

      it "ne déconnecte pas le super admin, laisse le reste de la session intacte et retourne au super admin" do
        delete :destroy

        expect(session["warden.user.super_admin.key"]).to be_present
        expect(session[:some_unrelated_key]).to eq("devrait survivre")
        expect(session[:super_admin_signed_in_as_agent]).to be_nil
        expect(response).to redirect_to(super_admins_agents_path)
      end

      it "déconnecte bien l'agent usurpé et affiche un message de confirmation" do
        delete :destroy

        expect(session["warden.user.agent.key"]).to be_nil
        expect(flash[:notice]).to eq("Le compte de #{agent.email} a été supprimé.")
      end
    end
  end
end
