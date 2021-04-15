module OrganisationsHelper
  def organisation_home_path(organisation)
    if organisation.recent?
      admin_organisation_setup_checklist_path(organisation)
    else
      admin_organisation_agent_agenda_path(organisation, current_agent)
    end
  end

  def setup_checklist_item(value)
    if value
      tag.i(nil, class: "far fa-check-square", style: "color: green")
    else
      tag.i(nil, class: "far  fa-square")
    end
  end
end
