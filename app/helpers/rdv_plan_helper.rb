module RdvPlanHelper
  def modalites_collection
    Lieu.enabled.where(organisation_id: current_agent.organisations.select(:id)).map do |l|
      ["public_office-#{l.id}", sanitize(" #{lieu_icon} Sur place à #{l.name} - #{l.address}")]
    end + [
      ["phone", sanitize(" #{phone_icon} Par téléphone")],
      ["visio", sanitize(" #{visio_icon} Par visioconférence")],
    ]
  end
end
