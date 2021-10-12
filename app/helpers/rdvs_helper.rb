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

  def rdv_danger_badge(rdvs)
    Rails.cache.fetch(["rdv_danger_badge", rdvs.to_sql.hash], expires_in: 2.minutes) do
      count = rdvs.status("unknown_past").count
      tag.span(count, class: "badge badge-danger") if count.positive?
    end
  end

  def rdv_status_value(status)
    return ["Tous les rdvs", ""] if status.blank?

    Rdv.statuses.to_a.find { |s| s[0] == status }
  end

  def rdv_starts_at_and_duration(rdv, format)
    return l(rdv.starts_at, format: format) if rdv.duration_in_min.blank?

    "#{l(rdv.starts_at, format: format)} (#{rdv.duration_in_min} minutes)"
  end

  def rdv_status_dropdown_toggle(rdv)
    tag.div(data: { toggle: "dropdown" },
            class: "dropdown-toggle btn rdv-status-#{rdv.temporal_status}") do
      I18n.t("activerecord.attributes.rdv.statuses.#{rdv.temporal_status}")
    end
  end

  def rdv_status_dropdown_item(rdv, agent, status, remote)
    link_to admin_organisation_rdv_path(rdv.organisation, rdv, rdv: { status: status, active_warnings_confirm_decision: true }, agent_id: agent&.id),
            method: :put,
            class: "dropdown-item",
            data: { confirm: t("activerecord.attributes.rdv.statuses/confirm.#{status}") },
            remote: remote do
      tag.span do
        tag.i(class: "fa fa-circle mr-1 rdv-status-#{status}") +
          t("activerecord.attributes.rdv.statuses/action.#{status}") +
          tag.div(t("activerecord.attributes.rdv.statuses/explanation.#{status}"), class: "text-wrap text-muted")
      end
    end
  end

  def rdv_status_delete_dropdown_item(rdv, agent)
    link_to admin_organisation_rdv_path(rdv.organisation, rdv, agent_id: agent&.id),
            method: :delete,
            class: "dropdown-item",
            data: { confirm: t("admin.rdvs.delete.confirm") } do
      tag.div(t("helpers.delete"), class: "text-danger") +
        tag.div(t("admin.rdvs.delete.details"), class: "text-wrap text-muted")
    end
  end
end
