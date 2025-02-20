RSpec.describe DemandeSupportForm do
  subject(:form) { described_class.new(**attributes) }

  context "tous les attributs présents" do
    let(:attributes) do
      {
        current_domain: Domain::RDV_MAIRIE,
        role: "usager",
        sujet: "Je suis perdue",
        first_name: "Jeanne",
        last_name: "Jacques",
        phone_number: "0603040506",
        email: "jean@pol.fr",
        message: "Je suis perdue, aidez-moi !\nJe ne retrouve pas mon mot de passe. Merci. JJ.",
      }
    end

    it { is_expected.to be_valid }

    it "appele CreateZammadTicket" do
      expect(CreateZammadTicketJob).to receive(:perform_later)
      form.submit
    end
  end

  context "un attribut manquant" do
    let(:attributes) do
      {
        current_domain: Domain::RDV_MAIRIE,
        role: "usager",
        sujet: "Je suis perdue",
        first_name: "Jeanne",
        # missing last name
        phone_number: "0603040506",
        email: "jean@pol.fr",
        message: "Je suis perdue, aidez-moi !\nJe ne retrouve pas mon mot de passe. Merci. JJ.",
      }
    end

    it { is_expected.not_to be_valid }

    it "n’appele pas CreateZammadTicket" do
      expect(CreateZammadTicketJob).not_to receive(:perform_later)
      form.submit
    end
  end

  context "le message est trop long" do
    let(:attributes) do
      {
        current_domain: Domain::RDV_MAIRIE,
        role: "usager",
        sujet: "Je suis perdue",
        first_name: "Jeanne",
        last_name: "Jacques",
        phone_number: "0603040506",
        email: "jean@pol.fr",
        message: "Je suis perdue, aidez-moi !\nJe ne retrouve pas mon mot de passe. Merci. JJ." * 10_000,
      }
    end

    it { is_expected.not_to be_valid }

    it "n’appele pas CreateZammadTicket" do
      expect(CreateZammadTicketJob).not_to receive(:perform_later)
      form.submit
    end
  end
end
