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
    if rdv.collectif?
      if rdv.name.present?
        "#{rdv.motif.name} : #{rdv.name}"
      else
        rdv.motif.name
      end
    else
      rdv_individuel_title_for_agent(rdv)
    end
  end

  def rdv_status_tag(rdv)
    tag.span(rdv.human_attribute_value(:status), class: "badge badge-info rdv-status rdv-status-#{rdv.status}")
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
      Rdv.human_attribute_value(:status, rdv.temporal_status, disable_cast: true)
    end
  end

  def rdv_status_dropdown_item(rdv, agent, status, remote)
    link_to admin_organisation_rdv_path(rdv.organisation, rdv, rdv: { status: status, ignore_benign_errors: true }, agent_id: agent&.id),
            method: :put,
            class: "dropdown-item",
            data: { confirm: change_status_confirmation_message(rdv, status) },
            remote: remote do
      tag.span do
        tag.i(class: "fa fa-circle mr-1 rdv-status-#{status}") +
          Rdv.human_attribute_value(:status, status, context: :action) +
          tag.div(Rdv.human_attribute_value(:status, status, context: :explanation), class: "text-wrap text-muted")
      end
    end
  end

  def change_status_confirmation_message(rdv, status)
    return "" if rdv.past?
    return I18n.t("admin.rdvs.message.confirm.simple_cancel") if cancel_rdv_to_not_notify?(rdv, status)
    return I18n.t("admin.rdvs.message.confirm.cancel_with_notification") if cancel_rdv_to_notify?(rdv, status)
    return I18n.t("admin.rdvs.message.confirm.reinit_status") if reset_futur_rdv?(rdv, status)

    ""
  end

  def cancel_rdv_to_not_notify?(rdv, status)
    %w[revoked excused].include?(status) && rdv.rdvs_users.select(&:send_lifecycle_notifications?).empty?
  end

  def cancel_rdv_to_notify?(rdv, status)
    %w[revoked excused].include?(status) && rdv.rdvs_users.select(&:send_lifecycle_notifications?).any?
  end

  def reset_futur_rdv?(rdv, status)
    status == "unknown" && !rdv.past?
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

  private

  def rdv_individuel_title_for_agent(rdv)
    (rdv.created_by_user? ? "@ " : "") +
      rdv.users&.map(&:full_name)&.to_sentence +
      (rdv.motif.home? ? " 🏠" : "") +
      (rdv.motif.phone? ? " ☎️" : "")
  end
end
