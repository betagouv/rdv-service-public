def mock_ants_status(application_id:, status: "validated", appointments: [])
  stub_request(:get, "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status")
    .with(query: { application_ids: application_id })
    .to_return(
      status: 200,
      body: {
        application_id => {
          status: status,
          appointments: appointments,
        },
      }.to_json
    )
end

def mock_ants_status_invalid_application_id(application_id:)
  stub_request(:get, "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status")
    .with(query: { application_ids: application_id })
    .to_return(
      status: 422,
      body: <<~JSON
        {
          "detail": [
            {
              "loc": [
                "query",
                "application_ids",
                0
              ],
              "msg": "string does not match regex \\"^([A-Z0-9]{10}\\"",
              "type": "value_error.str.regex",
              "ctx": {
                "pattern": "^[A-Z0-9]{10}$"
              }
            }
          ]
        }
      JSON
    )
end
