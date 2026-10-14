RSpec.describe AntsApi, type: :service do
  include_context "rdv_mairie_api_authentication"

  describe ".status" do
    context "when credentials are incorrect" do
      before do
        stub_request_ants_status("1122334455", meeting_point_id: "11").to_return(
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
          described_class.status(ants_pre_demande_number: "1122334455", meeting_point_id: "11")
        end.to raise_error(AntsApi::ApiRequestError, "code:401, body:{\n  \"detail\": \"X-RDV-OPT-AUTH-TOKEN header invalid\"\n}\n")
      end
    end

    it "envoie le token d'authentification et retourne le statut de la pré-demande" do
      stub = stub_ants_status_ok("1122334455", meeting_point_id: "11", status: "validated")
        .with(headers: { "Accept" => "application/json", "X-Rdv-Opt-Auth-Token" => "fake-token" })

      result = described_class.status(ants_pre_demande_number: "1122334455", meeting_point_id: "11")

      expect(result).to eq({ "status" => "validated", "appointments" => [] })
      expect(stub).to have_been_requested
    end

    it "lève une ApiRequestError sur une erreur 500" do
      stub_request_ants_status("1122334455", meeting_point_id: "11").to_return(status: 500, body: "oops")

      expect do
        described_class.status(ants_pre_demande_number: "1122334455", meeting_point_id: "11")
      end.to raise_error(AntsApi::ApiRequestError, "code:500, body:oops")
    end

    it "lève une erreur de timeout lors d'un timeout" do
      stub_request_ants_status("1122334455", meeting_point_id: "11").to_timeout

      expect do
        described_class.status(ants_pre_demande_number: "1122334455", meeting_point_id: "11")
      end.to raise_error(Typhoeus::Errors::TimeoutError)
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
          ants_pre_demande_number: "XXXX",
          management_url: "https://gerer-rdv.com",
          meeting_point_id: "123456",
          meeting_point: "Mairie de Sannois",
          appointment_date: "2023-04-03T08:45:00"
        )
        expect(result).to eq({ "success" => true })
      end
    end
  end

  describe ".delete" do
    it "envoie une requête DELETE avec les paramètres en query et retourne le body parsé" do
      stub = stub_request(:delete, "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments")
        .with(
          query: {
            application_id: "XXXX",
            appointment_date: "2023-04-03T08:45:00",
            meeting_point: "Mairie de Sannois",
            meeting_point_id: "123456",
          },
          headers: { "Accept" => "application/json", "X-Rdv-Opt-Auth-Token" => "fake-token" }
        )
        .to_return(status: 200, body: { rowcount: 1 }.to_json)

      result = described_class.delete(
        ants_pre_demande_number: "XXXX",
        meeting_point: "Mairie de Sannois",
        meeting_point_id: "123456",
        appointment_date: "2023-04-03T08:45:00"
      )

      expect(result).to eq({ "rowcount" => 1 })
      expect(stub).to have_been_requested
    end
  end
end
