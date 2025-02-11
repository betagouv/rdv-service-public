def stub_request_ants_status(application_id, meeting_point_id: nil)
  expected_query = { application_ids: application_id }
  expected_query[:meeting_point_id] = meeting_point_id.to_s if meeting_point_id.present?
  stub_request(:get, "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status")
    .with(query: hash_including(expected_query))
end

def stub_ants_status_ok(application_id, status: "validated", appointments: [])
  stub_request_ants_status(application_id).to_return(
    status: 200,
    body: { application_id => { status: status, appointments: appointments } }.to_json
  )
end

def stub_ants_create(application_id)
  stub_request(:post, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments/*})
    .with(query: hash_including({ "application_id" => application_id }))
    .to_return(
      status: 200,
      body: { success: true }.to_json
    )
end

def stub_ants_delete(application_id)
  stub_request(:delete, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments/*})
    .with(query: hash_including({ "application_id" => application_id }))
    .to_return(
      status: 200,
      body: { rowcount: 1 }.to_json
    )
end
