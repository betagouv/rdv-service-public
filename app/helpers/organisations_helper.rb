module OrganisationsHelper
  def organisation_home_path(organisation)
    if organisation.recent?
      organisation_setup_checklist_path(organisation)
    else
      organisation_agent_path(organisation, current_agent)
    end
  end

  def setup_checklist_item(value)
    if value
      content_tag(:i, nil, class: "far fa-check-square", style: "color: green")
    else
      content_tag(:i, nil, class: "far  fa-square")
    end
  end

  def organisation_human_id(organisation)
    content_tag(
      :span,
      organisation.human_id,
      class: "badge badge-light text-monospace"
    )
  end

  def organisation_zone_color(organisation)
    "##{Digest::MD5.hexdigest("orga-#{organisation.id}")[0..5]}"
  end
end
