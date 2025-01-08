module RdvPlanHelper
  def modalites_collection
    [
      ["phone", sanitize(" #{icon('fr-icon-phone-fill')} Par téléphone")],
      ["visio", sanitize(" #{icon('fr-icon-mac-fill')} Par visioconférence")],
    ] + Lieu.enabled.where(organisation_id: current_agent.organisations.select(:id)).map do |l|
      ["public_office-#{l.id}", sanitize(" #{lieu_icon} Sur place à #{l.name} - #{l.address}")]
    end
  end
end
