json.array! @rdvs do |rdv|
  json.title rdv_title_in_agenda(rdv)
  json.id rdv.id
  json.extendedProps do
    json.organisationName rdv.organisation&.name
    json.status rdv.status
    if @organisation.territory.enable_waiting_room_color_field
      json.userInWaitingRoom rdv.user_in_waiting_room?
    end
    json.readableStatus rdv.human_attribute_value(:status)
    json.motif rdv.motif_name
    json.lieu rdv.public_office? && rdv.lieu&.name
    json.past rdv.past?
    json.duration rdv.duration_in_min
  end
  json.start rdv.starts_at.as_json
  json.end rdv.ends_at.as_json

  # url pour modifier le rendez-vous
  # TODO trouver un meilleur nom à cet attribut pour en plus avoir besoin de ce commentaire
  json.url admin_organisation_rdv_path(rdv.organisation, rdv, agent_id: params[:agent_id]) if rdv.organisation == @organisation
  if rdv.organisation == @organisation
    json.textColor text_color(rdv.motif&.color)
    json.backgroundColor rdv.motif&.color
  else
    json.textColor "white"
    json.backgroundColor "#757575" # Use a dark enough gray to be accessible
  end
end
