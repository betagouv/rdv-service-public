module AgentsHelper
  def current_agent?(agent)
    agent.id == current_agent.id
  end

  def me_tag(agent)
    content_tag(:span, "Vous", class: "badge badge-info") if current_agent?(agent)
  end

  def admin_tag(agent)
    content_tag(:span, "Admin", class: "badge badge-danger") if agent.role_in_organisation(current_organisation).admin?
  end

  def delete_dropdown_link(agent)
    link_to "Supprimer", admin_organisation_agent_path(current_organisation, agent), data: { confirm: "Êtes-vous sûr de vouloir supprimer cet agent ?" }, method: :delete, class: "dropdown-item" if policy([:agent, agent]).destroy?
  end

  def build_link_to_rdv_wizard_params(creneau, form)
    params = {}
    params[:step] = 2
    params[:starts_at] = creneau.starts_at
    params[:motif_id] = creneau.motif.id
    params[:lieu_id] = creneau.lieu.id
    params[:organisation_id] = creneau.motif.organisation_id
    params[:duration_in_min] = creneau.motif.default_duration_in_min
    params["agent_ids"] = [creneau.agent_id]
    params["user_ids"] = form.user_ids if form.user_ids.present?
    params["context"] = form.context if form.context.present?
    params
  end

  def display_meta_note(note)
    meta = content_tag(:span, "le #{l(note.created_at.to_date)}", title: l(note.created_at))
    meta += " par #{note.agent.full_name_and_service}"
    content_tag(:span, meta, class: "font-italic")
  end

  def agents_to_sentence(agents)
    agents.map(&:full_name_and_service).sort.to_sentence
  end

  def menu_top_level_item
    {
      "menu-agendas" => "planning",
      "menu-plages-ouvertures" => "planning",
      "menu-absences" => "planning",
      "menu-agents" => "settings",
      "menu-invitations" => "settings",
      "menu-lieux" => "settings",
      "menu-motifs" => "settings",
      "menu-organisation" => "settings",
      "menu-organisation-stats" => "settings",
      "menu-stats" => "account",
      "men-department-sectors" => "",
      "men-department-zones" => "",
      "men-department-setup-checklist" => "",
      "men-department-zone-imports" => "",
    }[content_for(:menu_item)]
  end

  def selectable_planning_agents_options
    path_helper_name = content_for(:menu_agent_select_path_helper_name) || :admin_organisation_agent_agenda_path
    options_for_select(
      policy_scope(Agent)
        .joins(:organisations).where(organisations: { id: current_organisation.id })
        .complete.active.order_by_last_name
        .map do |agent|
        [
          agent.full_name,
          agent.id,
          { 'data-url': send(path_helper_name, current_organisation, agent.id) }
        ]
      end,
      selected: agent_for_left_menu.id
    )
  end

  def agent_for_left_menu
    @agent&.persisted? ? @agent : current_agent
  end
end
