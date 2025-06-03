require "rails_helper"

RSpec.describe Users::DemandesSupportMailer, type: :mailer do
  describe "#conversation_created" do
    let(:mail) do
      described_class.with(
        conversation_id: 46,
        email: "user@example.com",
        domain: "RDV_SOLIDARITES",
        sujet: "Problème de connexion",
        message: "Je n'arrive pas à me connecter\nPouvez-vous m'aider ?"
      ).conversation_created
    end

    it "renders the headers" do
      expect(mail.subject).to eq("[#46] Nouveaux messages dans cette conversation")
      expect(mail.to).to eq(["user@example.com"])
      expect(mail.from).to eq(["assistance@rdv-solidarites.fr"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Nous avons bien reçu votre demande de support")
      expect(mail.body.encoded).to match("Problème de connexion")
      expect(mail.body.encoded).to match("Je n'arrive pas à me connecter")
    end
  end
end
