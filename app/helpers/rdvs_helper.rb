# frozen_string_literal: true

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
    tag.span(Rdv.human_enum_name(:status, rdv.status), class: "badge badge-info rdv-status rdv-status-#{rdv.status}")
  end

  def no_rdv_for_users
    sentence = "Vous n'avez pas de RDV "
    sentence += params[:past].present? ? "passés" : "à venir"
    sentence
  end

  def human_location(rdv)
    text = rdv.address_complete
    text = safe_join([text, "Adresse non renseignée"], " - ") if rdv.address.blank?
    text = safe_join([text, tag.span("Fermé", class: "badge badge-danger")]) if rdv.lieu.present? && !rdv.lieu.enabled?
    text
  end

  def rdv_tag(rdv)
    if rdv.cancelled_at
      tag.span("Annulé", class: "badge badge-warning")
    elsif rdv.starts_at.future?
      tag.span("À venir", class: "badge badge-info")
    end
  end

  def unknown_past_agent_rdvs_danger_bage
    unknown_past_rdvs = current_organisation.rdvs.joins(:agents).where(agents: { id: current_agent }).status("unknown_past").count
    rdv_danger_badge(unknown_past_rdvs)
  end

  def rdv_danger_badge(count)
    tag.span(count, class: "badge badge-danger") if count.positive?
  end

  def rdv_danger_icon(count)
    tag.i(nil, class: "fa fa-exclamation-circle text-danger") if count.positive? && !stats_path?
  end

  def rdv_status_value(status)
    return ["Tous les rdvs", ""] if status.blank?

    Rdv.statuses.to_a.find { |s| s[0] == status }
  end

  def rdv_starts_at_and_duration(rdv, format)
    return l(rdv.starts_at, format: format) if rdv.duration_in_min.blank?

    "#{l(rdv.starts_at, format: format)} (#{rdv.duration_in_min} minutes)"
  end

  def rdv_possible_statuses_option_items(rdv)
    rdv.possible_statuses.map do |status|
      temporal_status = Rdv.temporal_status(status, rdv.starts_at)
      [I18n.t("activerecord.attributes.rdv.statuses.#{temporal_status}"), status]
    end
  end
end
