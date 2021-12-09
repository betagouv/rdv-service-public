# frozen_string_literal: true

module OrganisationsHelper
  def show_checklist?(organisation, agent)
    1.week.ago < organisation.created_at && agent.admin_in_organisation?(organisation)
  end

  def organisation_home_path(organisation, agent)
    if show_checklist?(organisation, agent)
      admin_organisation_setup_checklist_path(organisation)
    else
      admin_organisation_agent_agenda_path(organisation, agent)
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
