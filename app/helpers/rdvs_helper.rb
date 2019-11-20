module RdvsHelper
  def agents_to_sentence(rdv)
    rdv.agents.map(&:full_name_and_service).sort.to_sentence
  end

  def users_to_sentence(rdv)
    rdv.users.map(&:full_name).sort.to_sentence
  end

  def no_rdv_for_users
    sentence = "Vous n'avez pas de RDV "
    sentence += params[:past].present? ? "passé." : "à venir."
    sentence
  end

  def human_location(rdv)
    rdv.location.blank? ? 'Non précisé' : rdv.location
  end

  def future_tag(rdv)
    content_tag(:span, 'À venir', class: 'badge badge-info') if rdv.starts_at.future?
  end
end
