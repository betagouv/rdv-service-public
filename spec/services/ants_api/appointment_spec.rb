RSpec.describe AntsApi::Appointment, type: :service do
  include_context "rdv_mairie_api_authentication"

  describe ".find_by" do
    context "when credentials are incorrect" do
      before do
        stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status}).to_return(
          status: 401,
          body: <<~JSON
            {
              "detail": "X-RDV-OPT-AUTH-TOKEN header invalid"
            }
          JSON
        )
      end

      it "raises an error" do
        expect do
          described_class.find_by(application_id: "1122334455", management_url: "https://rdv-solidarites.fr")
        end.to raise_error(AntsApi::Appointment::ApiRequestError, "code:401, body:{\n  \"detail\": \"X-RDV-OPT-AUTH-TOKEN header invalid\"\n}\n")
      end
    end
  end

  describe "#create" do
    context "when creation is successful" do
      before do
        stub_request(:post, "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments?application_id=XXXX&appointment_date=2023-04-03T08:45:00&management_url=https://gerer-rdv.com&meeting_point=Mairie%20de%20Sannois").to_return(
          status: 200,
          body: <<~JSON
            {
              "success": true
            }
          JSON
        )
      end

      it "returns request body" do
        appointment = described_class.new(application_id: "XXXX", management_url: "https://gerer-rdv.com", meeting_point: "Mairie de Sannois", appointment_date: "2023-04-03T08:45:00")
        expect(appointment.create).to eq({ "success" => true })
      end
    end
  end
end
