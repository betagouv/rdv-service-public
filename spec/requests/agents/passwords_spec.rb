RSpec.describe "agents/passwords", type: :request do
  describe "POST /agents/password" do
    context "quand le paramètre email est absent" do
      let!(:intervenant) { create(:agent, :intervenant) }

      it "n'envoie pas de reset_password_instructions à un intervenant sans email" do
        expect do
          post agent_password_path, params: { agent: {} }
        end.not_to have_enqueued_mail(CustomDeviseMailer, :reset_password_instructions)
      end
    end
  end
end
