json.array! @rdvs do |rdv|
  json.title rdv_title_for_agent(rdv)
  json.id rdv.id
  json.extendedProps do
    json.status rdv.status
    json.readableStatus Rdv.human_enum_name(:status, rdv.status)
    json.motif rdv.motif.name
    json.past rdv.past?
    json.duration rdv.duration_in_min
  end
  json.start rdv.starts_at
  json.end rdv.ends_at
  json.url admin_organisation_rdv_path(rdv.organisation, rdv, agent_id: params[:agent_id])
  json.backgroundColor rdv.motif&.color
end
