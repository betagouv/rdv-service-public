# frozen_string_literal: true

module ParticipationsHelper
  def participation_status_dropdown_toggle(rdvs_user)
    tag.div(data: { toggle: "dropdown" },
            class: "dropdown-toggle btn rdv-status-#{rdvs_user.temporal_status}") do
      RdvsUser.human_attribute_value(:status, rdvs_user.temporal_status, disable_cast: true)
    end
  end

  def participation_delete_dropdown_item(rdvs_user, agent)
    link_to admin_organisation_rdv_participation_path(rdvs_user.rdv.organisation, rdvs_user.rdv, rdvs_user, agent_id: agent&.id),
            method: :delete,
            class: "dropdown-item",
            data: { confirm: t("admin.rdvs_users.delete.confirm") } do
      tag.div(t("admin.rdvs_users.delete.title"), class: "text-danger") +
        tag.div(t("admin.rdvs_users.delete.details"), class: "text-wrap text-muted")
    end
  end
end
