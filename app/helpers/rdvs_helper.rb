module RdvsHelper
  def rdv_title(rdv, date_format: :human)
    article = date_format == :time_only ? "À" : "Le"
    "#{article} #{l(rdv.starts_at, format: date_format)} " \
      "(durée : #{rdv.duration_in_min} minutes)"
  end

  def rdv_title_for_agent(rdv)
    (rdv.created_by_user? ? "@ " : "") +
      rdv.users&.map(&:full_name)&.to_sentence +
      (rdv.motif.home? ? " 🏠" : "") +
      (rdv.motif.phone? ? " ☎️" : "")
  end

  def rdv_title_for_user(rdv, user)
    "#{user.full_name} <> #{rdv.motif&.name}"
  end

  def agents_to_sentence(rdv)
    rdv.agents.map(&:full_name_and_service).sort.to_sentence
  end

  def users_to_links(rdv)
    safe_join(rdv.users.order_by_last_name.map { user_to_link(_1) }, ", ")
  end

  def user_to_link(user)
    if user.organisations.include?(current_organisation)
      link_to user.full_name, admin_organisation_user_path(current_organisation, user)
    else
      "#{user.full_name} - l'usager a été supprimé"
    end
  end

  def users_to_sentence(rdv)
    return rdv.users.map(&:full_name).sort.to_sentence if current_agent

    users = []
    rdv.users.each do |user|
      users << user if user == current_user || current_user.relatives.include?(user)
    end
    users.map(&:full_name).sort.to_sentence
  end

  def rdv_status_tag(rdv)
    content_tag(:span, Rdv.human_enum_name(:status, rdv.status), class: "badge badge-info")
  end

  def no_rdv_for_users
    sentence = "Vous n'avez pas de RDV "
    sentence += params[:past].present? ? "passé." : "à venir."
    sentence
  end

  def human_location(rdv)
    text = rdv.address_complete
    text += " - Adresse non renseignée" if rdv.address.blank?
    text
  end

  def rdv_tag(rdv)
    if rdv.cancelled_at
      content_tag(:span, "Annulé", class: "badge badge-warning")
    elsif rdv.starts_at.future?
      content_tag(:span, "À venir", class: "badge badge-info")
    end
  end

  def stats_rdv_path(status)
    case controller_name
    when "stats"
      if params[:agent_id].present?
        admin_organisation_agent_rdvs_path(current_organisation, params[:agent_id], status: status, default_period: true)
      else
        admin_organisation_rdvs_path(current_organisation, status: status, default_period: true)
      end
    when "users", "relatives"
      admin_organisation_user_rdvs_path(current_organisation, params[:id], status: status)
    end
  end

  def stats_path?
    request.path.match(%r{^/stats.*})
  end

  def unknown_past_rdvs_danger_bage
    unknown_past_rdvs = current_organisation.rdvs.status("unknown_past").where(created_at: Stat.default_date_range).count
    rdv_danger_badge(unknown_past_rdvs)
  end

  def unknown_past_agent_rdvs_danger_bage
    unknown_past_rdvs = current_organisation.rdvs.joins(:agents).where(agents: { id: current_agent }).status("unknown_past").where(created_at: Stat.default_date_range).count
    rdv_danger_badge(unknown_past_rdvs)
  end

  def rdv_danger_badge(count)
    content_tag(:span, count, class: "badge badge-danger") if count.positive?
  end

  def rdv_danger_icon(count)
    content_tag(:i, nil, class: "fa fa-exclamation-circle text-danger") if count.positive? && !stats_path?
  end

  def link_to_rdvs(status, clasz: "btn-outline-white")
    link_to "Voir", stats_rdv_path(status), class: "btn #{clasz}" unless stats_path?
  end

  def rdv_status_value(status)
    if status.blank?
      ["Tous les rdvs", ""]
    else
      Rdv.statuses.to_a.find { |s| s[0] == status }
    end
  end

  def rdv_time_and_duration(rdv)
    "#{l(rdv.starts_at, format: :time_only)} (#{rdv.duration_in_min} minutes)"
  end

  def rdv_status_for(rdv)
    if rdv.starts_at < Date.today
      ["unknown_future", "excused"]
    elsif rdv.starts_at.to_date == Date.today
      ["unknown_future", "waiting", "notexcused", "excused"]
    else
      ["unknown_past", "notexcused", "excused"]
    end.map{|x| rdv_status_item(x)}
  end

  def rdv_status_item(status)
    [I18n.t("activerecord.attributes.rdv.statuses.#{status}"), status.split("_")[0]]
  end

  def rdv_status_label(rdv)
    status = rdv.status
    status = "unknown_future" if rdv.unknown? && rdv.starts_at.to_date >= Date.today
    status = "unknown_past" if rdv.unknown? && rdv.starts_at.to_date < Date.today
    I18n.t("activerecord.attributes.rdv.statuses.#{status}")
  end

end

