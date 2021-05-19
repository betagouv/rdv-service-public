# frozen_string_literal: true

json.array! @rdvs do |rdv|
  json.title rdv_title_for_agent(rdv) + (rdv.overlapping_plages_ouvertures? ? " ⚠️" : "")
  json.id rdv.id
  json.extendedProps do
    json.organisationName rdv.organisation&.name
    json.status rdv.status
    json.readableStatus Rdv.human_enum_name(:status, rdv.status)
    json.motif rdv.motif.name
    json.lieu rdv.public_office? && rdv.lieu&.name
    json.past rdv.past?
    json.duration rdv.duration_in_min
    json.overlappingPlagesOuvertures rdv.overlapping_plages_ouvertures?
  end
  json.start rdv.starts_at
  json.end rdv.ends_at

  # url pour éditer le rendez-vous
  # TODO trouver un meilleur nom à cet attribut pour en plus avoir besoin de ce commentaire
  json.url admin_organisation_rdv_path(rdv.organisation, rdv, agent_id: params[:agent_id]) if rdv.organisation == @organisation
  if rdv.organisation == @organisation
    json.textColor text_color(rdv.motif&.color)
    json.backgroundColor rdv.motif&.color
  else
    json.textColor "white"
    json.backgroundColor "darkgrey"
  end
end
