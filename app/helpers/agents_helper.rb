module AgentsHelper
  def current_agent?(agent)
    agent.id == current_agent.id
  end

  def me_tag(agent)
    tag.span("Vous", class: "badge badge-info") if current_agent?(agent)
  end

  def build_link_to_rdv_wizard_params(creneau, form)
    params = {}
    params[:step] = 2
    params[:starts_at] = creneau.starts_at
    params[:motif_id] = creneau.motif.id
    params[:lieu_id] = creneau.lieu&.id
    params[:organisation_id] = creneau.motif.organisation_id
    params[:duration_in_min] = creneau.motif.default_duration_in_min
    # Pour filtrer les agents depuis la recherche de créneaux coté agent
    params["agent_ids"] = [creneau.agent.id].compact
    params["user_ids"] = form.user_ids if form.user_ids.present?
    params["context"] = form.context if form.context.present?
    params
  end

  def agents_to_sentence(agents)
    agents.map(&:full_name_and_service).sort.to_sentence
  end

  def menu_top_level_item
    {
      "menu-agendas" => "planning",
      "menu-plages-ouvertures" => "planning",
      "menu-absences" => "planning",
      "menu-rdvs-collectifs-list" => "planning",
      "menu-agents" => "settings",
      "menu-invitations" => "settings",
      "menu-lieux" => "settings",
      "menu-motifs" => "settings",
      "menu-organisation" => "settings",
      "menu-online-booking" => "settings",
      "menu-organisation-stats" => "stats",
      "menu-stats" => "stats",
    }[content_for(:menu_item)]
  end

  def planning_agent_select(agent, path_helper_name)
    # See also planning-agent-select.js
    # path_helper_name lets us build the path of the current subsection (Agenda, PlageOuverture, Absence)
    url_template = send(path_helper_name, current_organisation, "__AGENT__")
    preselected_option = [
      agent.reverse_full_name,
      agent.id,
      {
        "data-url": send(path_helper_name, current_organisation, agent),
      },
    ]
    select_tag(
      :planning_agent_select,
      options_for_select([preselected_option],
                         selected: agent.id),
      class: "select2-input form-control js-planning-agent-select",
      data: {
        "select2-config": {
          ajax: {
            url: admin_organisation_agents_path(current_organisation),
            dataType: "json",
            delay: 250,
          },
        },
        "url-template": url_template,
      }
    )
  end

  def navigation_scoped_by_agent_services?(current_agent, current_organisation)
    return false if current_agent.secretaire?

    !current_agent.roles.access_level_admin.exists?(organisation_id: current_organisation.id)
  end

  def current_organisation_in_left_menu(&block)
    if current_agent.organisations.count > 1
      link_to(".left-submenu-account", "data-toggle" => :collapse, "aria-expanded" => "false", class: "side-menu__item", &block)
    else
      tag.div(class: "pt-2 pr-2 pb-2 pl-3", &block)
    end
  end

  def access_level_label(access_level)
    AgentRole.human_attribute_value(:access_level, access_level, context: :explanation).html_safe # rubocop:disable Rails/OutputSafety
  end
end
