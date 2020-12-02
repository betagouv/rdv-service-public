RSpec.describe SupportTicketsController, type: :controller do
  render_views

  describe "POST #create" do
    let(:support_ticket_form) { SupportTicketForm.new }

    before do
      expect(SupportTicketForm).to receive(:new)
        .with(support_ticket_params)
        .and_return(support_ticket_form)
    end

    subject { post(:create, params: { support_ticket: support_ticket_params }) }

    context "broken params" do
      let(:support_ticket_params) { { subject: "n'importe quoi" } }
      before do
        expect(support_ticket_form).to receive(:save).and_return(false)
      end
      it { should render_template("static_pages/contact") }
    end

    context "valid params" do
      let(:support_ticket_params) do
        {
          subject: "Je suis usager et je n'arrive pas à accéder à mon compte",
          first_name: "Jean",
          last_name: "Jacques",
          email: "jean@jacques.fr",
          message: "Ca me gratte partout",
          departement: "73"
        }
      end
      before { expect(support_ticket_form).to receive(:save).and_return(true) }
      it { should redirect_to(contact_path(anchor: "")) }
    end
  end
end
