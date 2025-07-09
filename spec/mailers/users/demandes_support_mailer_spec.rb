require "rails_helper"

RSpec.describe Users::DemandesSupportMailer, type: :mailer do
  describe "#conversation_created" do
    let(:mail) do
      described_class.with(
        subject: "[#46] Nouveaux messages dans cette conversation",
        in_reply_to: "account/1/conversation/4ffdb710-5faf-486e-b2a5-1a002eedo54d@test-support.rdv-service-public.fr",
        email: "user@example.com",
        domain_id: "RDV_SOLIDARITES",
        demande_support_sujet: "Problème de connexion",
        demande_support_message: "Je n'arrive pas à me connecter\nPouvez-vous m'aider ?"
      ).conversation_created
    end

    it "renders the headers" do
      expect(mail.subject).to eq("[#46] Nouveaux messages dans cette conversation")
      expect(mail.to).to eq(["user@example.com"])
      expect(mail.from).to eq(["assistance@rdv-solidarites.fr"])
      expect(mail["In-Reply-To"].value).to eq("account/1/conversation/4ffdb710-5faf-486e-b2a5-1a002eedo54d@test-support.rdv-service-public.fr")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Nous avons bien reçu votre demande de support")
      expect(mail.body.encoded).to match("Problème de connexion")
      expect(mail.body.encoded).to match("Je n'arrive pas à me connecter")
    end
  end
end
