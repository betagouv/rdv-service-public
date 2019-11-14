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
end
