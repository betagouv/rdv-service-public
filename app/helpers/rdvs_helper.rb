module RdvsHelper

  def rdv_title(rdv)
    "Le #{l(rdv.starts_at, format: :human)} (durée : #{rdv.duration_in_min} minutes)"
  end

  def agents_to_sentence(rdv)
    rdv.agents.map(&:full_name_and_service).sort.to_sentence
  end

  def users_to_sentence(rdv)
    rdv.users.map(&:full_name).sort.to_sentence
  end

  def rdv_status_tag(rdv)
    content_tag(:span, Rdv.human_enum_name(:status, rdv.status), class: 'badge badge-info')
  end
  
  def human_location(rdv)
    rdv.location.blank? ? 'Non précisé' : rdv.location
  end

  def future_tag(rdv)
    content_tag(:span, 'À venir', class: 'badge badge-info') if rdv.starts_at.future?
  end
end
