module OrganisationsHelper
  def organisation_home_path(organisation)
    if organisation.recent?
      organisation_setup_checklist_path(organisation)
    else
      organisation_agent_path(organisation, current_agent)
    end
  end
end
