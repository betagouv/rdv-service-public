describe SupportTicketForm do
  describe "#save" do
    subject { support_ticket_form.save }

    context "valid attributes" do
      let(:support_ticket_form) do
        SupportTicketForm.new(
          subject: "Je suis usager et je n'arrive pas à accéder à mon compte",
          first_name: "Jean",
          last_name: "Jacques",
          email: "jean@jacques.fr",
          message: "Ca me gratte partout",
          departement: "73",
          city: "Chambéry, 73000"
        )
      end

      it "should call API" do
        expect(ZammadApi).to receive(:create_ticket)
          .with(
            "jean@jacques.fr",
            "Je suis usager et je n'arrive pas à accéder à mon compte - 73 - Jean Jacques",
            "Email: jean@jacques.fr\nPrénom: Jean\nNom: Jacques\nDépartement: 73\nCommune: Chambéry, 73000\n\nCa me gratte partout"
          ).and_return([true, {}])
        res = subject
        expect(res).to eq true
      end
    end

    context "invalid attributes" do
      let(:support_ticket_form) do
        SupportTicketForm.new(
          subject: "Je suis usager et je n'arrive pas à accéder à mon compte",
          first_name: "Jean",
          last_name: "Jacques",
          email: "jean@jacques.fr",
          message: "Ca me gratte partout"
          # missing dept & commune
        )
      end

      it "should not call API" do
        expect(ZammadApi).not_to receive(:create_ticket)
        res = subject
        expect(res).to eq false
      end
    end
  end
end
