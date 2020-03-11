module RdvsHelper
  def rdv_title(rdv)
    "Le #{l(rdv.starts_at, format: :human)} (durée : #{rdv.duration_in_min} minutes)"
  end

  def agents_to_sentence(rdv)
    rdv.agents.map(&:full_name_and_service).sort.to_sentence
  end

  def users_to_links(rdv)
    safe_join(rdv.users.order_by_last_name.map do |user|
      link_to user.full_name, user_show_path(user), target: '_blank'
    end, ", ")
  end

  def users_to_sentence(rdv)
    users = []
    rdv.users.each do |user|
      users << user if user == current_user || current_user.children.include?(user)
    end
    users.map(&:full_name).sort.to_sentence
  end

  def rdv_status_tag(rdv)
    content_tag(:span, Rdv.human_enum_name(:status, rdv.status), class: 'badge badge-info')
  end

  def no_rdv_for_users
    sentence = "Vous n'avez pas de RDV "
    sentence += params[:past].present? ? "passé." : "à venir."
    sentence
  end

  def human_location(rdv)
    rdv.location.blank? ? 'Non précisé' : rdv.location
  end

  def rdv_tag(rdv)
    if rdv.cancelled_at
      content_tag(:span, 'Annulé', class: 'badge badge-warning')
    elsif rdv.starts_at.future?
      content_tag(:span, 'À venir', class: 'badge badge-info')
    end
  end

  def callback_path(rdv)
    if params[:agent_id].present?
      organisation_agent_rdvs_path(rdv.organisation, params[:agent_id], page: params[:page])
    elsif params[:user_id].present?
      organisation_user_rdvs_path(rdv.organisation, params[:user_id], page: params[:page])
    else
      organisation_rdvs_path(rdv.organisation, page: params[:page])
    end
  end

  def stats_rdv_path(status)
    case controller_name
    when 'stats'
      organisation_rdvs_path(current_organisation, page: params[:page], status: status)
    when 'users' || 'chridren'
      organisation_user_rdvs_path(current_organisation, params[:id], page: params[:page], status: status)
    when 'agents'
      organisation_agent_rdvs_path(current_organisation, params[:id], page: params[:page], status: status)
    end
  end

  def stats_path?
    stats_path == request.path
  end

  def unknown_past_danger_bage
    unknown_past_rdvs = current_organisation.rdvs.status('unknown_past').where(created_at: Stat::DEFAULT_RANGE).count
    rdv_danger_badge(unknown_past_rdvs)
  end

  def rdv_danger_badge(count)
    content_tag(:span, count, class: 'badge badge-danger') if count.positive?
  end

  def rdv_danger_icon(count)
    content_tag(:i, nil, class: "fa fa-exclamation-circle text-danger") if count.positive?
  end

  def link_to_rdv(status, clasz: 'btn-outline-white')
    link_to 'Voir', stats_rdv_path('unknown_future'), class: "btn #{clasz}" unless stats_path?
  end
end
