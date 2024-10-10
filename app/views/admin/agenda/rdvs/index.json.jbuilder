json.array! @rdvs do |rdv|
  json.start rdv.starts_at.as_json
  json.end rdv.ends_at.as_json

  if Agent::RdvPolicy.new(current_agent, rdv).show?
    json.id rdv.id
    json.title rdv_title_in_agenda(rdv)
    json.url admin_organisation_rdv_path(rdv.organisation, rdv, agent_id: params[:agent_id])

    json.extendedProps do
      json.organisationName rdv.organisation.name
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

    if rdv.organisation == @organisation
      json.textColor text_color(rdv.motif&.color)
      json.backgroundColor rdv.motif&.color
    else
      json.textColor "white"
      json.backgroundColor "#757575" # Use a dark enough gray to be accessible
    end

  else # L'agent connecté n'a pas le droit d'afficher (#show) ce RDV
    json.title "Occupé⋅e (en RDV)"
    json.textColor "black"
    json.backgroundColor "#dadada" # Overridden by striped background in CSS
    json.extendedProps do
      json.unauthorizedRdvExplanation "Vous ne pouvez pas voir ce RDV parce qu'il a lieu dans un autre service ou une autre organisation"
    end
  end
end
