module RdvsHelper
  def rdv_title(rdv)
    if rdv.starts_at.to_date.today?
      I18n.t("rdvs.title_time_only", starts_at: l(rdv.starts_at, format: :time_only), duration: rdv.duration_in_min)
    else
      I18n.t("rdvs.title", starts_at: l(rdv.starts_at, format: :human), duration: rdv.duration_in_min)
    end
  end

  def rdv_title_for_agent(rdv)
    (rdv.created_by_user? ? "@ " : "") +
      rdv.users&.map(&:full_name)&.to_sentence +
      (rdv.motif.home? ? " 🏠" : "") +
      (rdv.motif.phone? ? " ☎️" : "")
  end

  def rdv_status_tag(rdv)
    content_tag(:span, Rdv.human_enum_name(:status, rdv.status), class: "badge badge-info rdv-status rdv-status-#{rdv.status}")
  end

  def no_rdv_for_users
    sentence = "Vous n'avez pas de RDV "
    sentence += params[:past].present? ? "passés" : "à venir"
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

  def unknown_past_rdvs_danger_bage
    unknown_past_rdvs = current_organisation.rdvs.status("unknown_past").count
    rdv_danger_badge(unknown_past_rdvs)
  end

  def unknown_past_agent_rdvs_danger_bage
    unknown_past_rdvs = current_organisation.rdvs.joins(:agents).where(agents: { id: current_agent }).status("unknown_past").count
    rdv_danger_badge(unknown_past_rdvs)
  end

  def rdv_danger_badge(count)
    content_tag(:span, count, class: "badge badge-danger") if count.positive?
  end

  def rdv_danger_icon(count)
    content_tag(:i, nil, class: "fa fa-exclamation-circle text-danger") if count.positive? && !stats_path?
  end

  def rdv_status_value(status)
    return ["Tous les rdvs", ""] if status.blank?

    Rdv.statuses.to_a.find { |s| s[0] == status }
  end

  def rdv_time_and_duration(rdv)
    "#{l(rdv.starts_at, format: :time_only)} (#{rdv.duration_in_min} minutes)"
  end

  def rdv_possible_statuses_option_items(rdv)
    rdv.possible_temporal_statuses.map do |status|
      [I18n.t("activerecord.attributes.rdv.statuses.#{status}"), status.split("_")[0]]
    end
  end
end
