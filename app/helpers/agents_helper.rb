module AgentsHelper
  def current_agent?(agent)
    agent.id == current_agent.id
  end

  def me_tag(agent)
    content_tag(:span, "Vous", class: "badge badge-info") if current_agent?(agent)
  end

  def admin_tag(agent)
    content_tag(:span, "Admin", class: "badge badge-danger") if agent.admin?
  end

  def delete_dropdown_link(agent)
    link_to "Supprimer", admin_organisation_agent_path(current_organisation, agent), data: { confirm: "Êtes-vous sûr de vouloir supprimer cet agent ?" }, method: :delete, class: "dropdown-item" if policy([:agent, agent]).destroy?
  end

  def build_link_to_rdv_wizard_params(creneau, user_ids)
    params = {}
    params[:step] = 2
    params[:starts_at] = creneau.starts_at
    params[:motif_id] = creneau.motif.id
    params[:lieu_id] = creneau.lieu.id
    params[:organisation_id] = creneau.motif.organisation_id
    params[:duration_in_min] = creneau.motif.default_duration_in_min
    params["agent_ids"] = [creneau.agent_id]
    params["user_ids"] = user_ids if user_ids.present?
    params
  end

  def duplicate_rdv_wizard_path(rdv)
    new_admin_organisation_rdv_wizard_step_path(
      step: 1,
      service_id: rdv.motif.service_id,
      agent_ids: rdv.agent_ids,
      user_ids: rdv.user_ids,
      **rdv.attributes.symbolize_keys.slice(
        :starts_at, :motif_id, :lieu_id, :organisation_id, :duration_in_min, :context
      )
    )
  end

  def display_meta_note(note)
    meta = content_tag(:span, "le #{l(note.created_at.to_date)}", title: l(note.created_at))
    meta += " par #{note.agent.full_name_and_service}"
    content_tag(:span, meta, class: "font-italic")
  end

  def agents_to_sentence(agents)
    agents.map(&:full_name_and_service).sort.to_sentence
  end
end
