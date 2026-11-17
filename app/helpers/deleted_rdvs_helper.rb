module DeletedRdvsHelper
  # Les DeletedRdv n'ont pas de foreign keys : une référence peut avoir disparu, ou ne plus être accessible
  # à l'agent. Dans ces cas on affiche du texte brut plutôt qu'un lien cassé.
  def link_to_if_present(label, path)
    path ? link_to(label, path) : label
  end

  def deleted_rdv_motif_link(deleted_rdv)
    motif = deleted_rdv.motif
    path = admin_organisation_motif_path(current_organisation, motif) if motif && Agent::MotifPolicy.new(current_agent, motif).show?
    link_to_if_present(deleted_rdv.motif_name.presence || motif&.name, path)
  end

  # Il n'y a pas de page "show" pour les lieux : on pointe vers l'édition, réservée aux admins.
  def deleted_rdv_lieu_link(deleted_rdv)
    lieu = deleted_rdv.lieu
    return if deleted_rdv.lieu_id.blank?
    return deleted_rdv_missing_reference(deleted_rdv.lieu_id) unless lieu

    path = edit_admin_organisation_lieu_path(current_organisation, lieu) if Agent::LieuPolicy.new(current_agent, lieu).edit?
    link_to_if_present(lieu.name, path)
  end

  def deleted_rdv_user_links(deleted_rdv, users_by_id)
    safe_join(deleted_rdv.user_ids.map do |id|
      user = users_by_id[id]
      next deleted_rdv_missing_reference(id) unless user

      path = admin_organisation_user_path(current_organisation, user) if Agent::UserPolicy.new(pundit_user, user).show?
      link_to_if_present(user.full_name, path)
    end, tag.br)
  end

  def deleted_rdv_agent_links(deleted_rdv, agents_by_id)
    safe_join(deleted_rdv.agent_ids.map do |id|
      agent = agents_by_id[id]
      next deleted_rdv_missing_reference(id) unless agent

      path = edit_admin_organisation_agent_path(current_organisation, agent) if !agent.soft_deleted? && Agent::AgentPolicy.new(current_agent, agent).edit?
      link_to_if_present(agent.full_name, path)
    end, tag.br)
  end

  private

  def deleted_rdv_missing_reference(id)
    tag.span("##{id} (supprimé)", class: "fr-text--xs fr-mb-0")
  end
end
