RSpec.describe IncomingZammadWebhookJob do
  subject { described_class.new.perform(payload) }

  context "user found by email" do
    let!(:user) { create(:user, email: "soukalina@gmail.com") }

    let(:payload) do
      {
        "ticket" => {
          "id" => "29104",
          "customer" => {
            "id" => "12204",
            "email" => "soukalina@gmail.com",
          },

        },
      }
    end

    it "should add a note with a link to the super admin user" do
      expect(ZammadApiClient).to receive(:create_note).with(satisfy do |note_params|
        expect(note_params[:ticket_id]).to eq "29104"
        expect(note_params[:body_html]).to include "http://www.rdv-mairie-test.localhost/super_admins/users/#{user.id}"
      end)
      subject
    end
  end
end
