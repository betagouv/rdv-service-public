# frozen_string_literal: true

describe SupportTicketForm do
  describe "#save" do
    subject { support_ticket_form.save }

    before { allow(Rails.env).to receive(:production?).and_return(true) }

    context "valid attributes" do
      let(:support_ticket_form) do
        described_class.new(
          subject: "Je suis usager et je n'arrive pas à accéder à mon compte",
          first_name: "Jean",
          last_name: "Jacques",
          email: "jean@jacques.fr",
          message: "Ca me gratte partout",
          city: "Chambéry, 73000"
        )
      end

      it "calls API" do
        allow(ZammadApi).to receive(:create_ticket)
          .with(
            "jean@jacques.fr",
            "Je suis usager et je n'arrive pas à accéder à mon compte - Jean Jacques",
            "Email: jean@jacques.fr\nPrénom: Jean\nNom: Jacques\nCommune: Chambéry, 73000\n\nCa me gratte partout"
          ).and_return([true, {}])
        res = subject
        expect(res).to eq true
      end
    end

    context "invalid attributes" do
      let(:support_ticket_form) do
        described_class.new(
          subject: "Je suis usager et je n'arrive pas à accéder à mon compte",
          first_name: "Jean",
          last_name: "Jacques",
          email: "jean@jacques.fr",
          message: "Ca me gratte partout"
          # missing commune
        )
      end

      it "does not call API" do
        expect(ZammadApi).not_to receive(:create_ticket)
        res = subject
        expect(res).to eq false
      end
    end
  end
end
