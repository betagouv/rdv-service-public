module WelcomeHelper
  def sectorisation_hint(geo_search)
    return nil if !geo_search.departement_sectorisation_enabled? || geo_search.empty_attributions?

    explanations = geo_search.matching_zones.map do |zone|
      (zone.level_street? ? "#{zone.street_name} " : "") +
        "#{zone.city_name} → " +
        zone.sector.attributions.to_a.group_by(&:organisation).map do |organisation, attributions|
          organisation.name + (attributions.all?(&:level_agent?) ? " (certains agents)" : "")
        end.join(", ")
    end
    content_tag(:div, class: "d-flex") do
      content_tag(:div, "Sectorisation :", class: "mr-1") +
        content_tag(:div, explanations.join("<br />").html_safe)
    end
  end
end
