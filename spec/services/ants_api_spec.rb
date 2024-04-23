RSpec.describe AntsApi, type: :service do
  include_context "rdv_mairie_api_authentication"

  describe ".status" do
    context "when credentials are incorrect" do
      before do
        stub_request(:get, "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status?application_ids=1122334455").to_return(
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
          described_class.status(application_id: "1122334455")
        end.to raise_error(AntsApi::ApiRequestError, "code:401, body:{\n  \"detail\": \"X-RDV-OPT-AUTH-TOKEN header invalid\"\n}\n")
      end
    end
  end

  describe ".create" do
    context "when creation is successful" do
      before do
        stub_request(:post, "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments?application_id=XXXX&appointment_date=2023-04-03T08:45:00&management_url=https://gerer-rdv.com&meeting_point=Mairie%20de%20Sannois&meeting_point_id=123456").to_return(
          status: 200,
          body: <<~JSON
            {
              "success": true
            }
          JSON
        )
      end

      it "returns request body" do
        result = described_class.create(
          application_id: "XXXX",
          management_url: "https://gerer-rdv.com",
          meeting_point_id: "123456",
          meeting_point: "Mairie de Sannois",
          appointment_date: "2023-04-03T08:45:00"
        )
        expect(result).to eq({ "success" => true })
      end
    end
  end
end
