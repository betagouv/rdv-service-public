# frozen_string_literal: true

module OrganisationsHelper
  def show_checklist?(organisation, agent)
    return false unless agent.admin_in_organisation?(organisation)
    return false unless agent.invitation_accepted_at # This shouldn't happen, but we'd rather be safe

    # The invitation_accepted_at column is a good indicator of how long the agent has been using the application
    if agent.conseiller_numerique?
      agent.invitation_accepted_at > 2.weeks.ago && agent.rdvs.count < 2
    else
      agent.invitation_accepted_at > 1.week.ago
    end
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
