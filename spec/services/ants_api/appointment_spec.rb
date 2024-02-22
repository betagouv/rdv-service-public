RSpec.describe AntsApi::Appointment, type: :service do
  include_context "rdv_mairie_api_authentication"

  describe "#request" do
    context "When credentials are incorrect" do
      before do
        stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status}).to_return(
          status: 401,
          body: "Unauthorized access"
        )
      end

      it "raises an error" do
        expect do
          described_class.find_by(application_id: "1122334455", management_url: "https://rdv-solidarites.fr")
        end.to raise_error(AntsApi::Appointment::ApiRequestError, "code:401, body:Unauthorized access")
      end
    end
  end
end
