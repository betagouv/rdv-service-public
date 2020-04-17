module AgentsHelper
  def current_agent?(agent)
    agent.id == current_agent.id
  end

  def me_tag(agent)
    content_tag(:span, 'Vous', class: 'badge badge-info') if current_agent?(agent)
  end

  def admin_tag(agent)
    content_tag(:span, 'Admin', class: 'badge badge-danger') if agent.admin?
  end

  def delete_dropdown_link(agent)
    link_to 'Supprimer', organisation_agent_path(current_organisation, agent), data: { confirm: "Êtes-vous sûr de vouloir supprimer cet agent ?" }, method: :delete, class: 'dropdown-item' if policy([:agent, agent]).destroy?
  end

  def build_link_to_rdv_wiard_params(lieu, motif, creneau, user)
    params = {}
    params[:step] = 2
    params[:starts_at] = creneau.starts_at
    params[:motif_id] = motif.id
    params[:plage_ouverture_location] = lieu.address
    params[:organisation_id] = motif.organisation_id
    params[:duration_in_min] = motif.default_duration_in_min
    params["agent_ids[]"] = creneau.agent_id
    params["user_ids[]"] = user.id if user
    params
  end
end
