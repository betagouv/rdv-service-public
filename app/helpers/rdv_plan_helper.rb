module RdvPlanHelper
  def modalites_collection
    result = []

    available_location_types = current_agent.motifs.active.where(organisation_id: current_agent.roles.select(:organisation_id)).pluck(:location_type)

    if available_location_types.include?("public_office")
      result += Lieu.enabled.where(organisation_id: current_agent.organisations.select(:id)).map do |l|
        ["public_office-#{l.id}", sanitize(" #{lieu_icon} Sur place à #{l.name} <br /> #{l.address}")]
      end
    end

    if available_location_types.include?("phone")
      result << ["phone", sanitize(" #{phone_icon} Par téléphone")]
    end

    if available_location_types.include?("visio")
      result << ["visio", sanitize(" #{visio_icon} Par visioconférence")]
    end

    if available_location_types.include?("home")
      result << ["home", sanitize(" #{home_icon} Au domicile de l'usager")]
    end

    result
  end
end
