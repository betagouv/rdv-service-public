module ParticipationsHelper

  def participation_status_dropdown_toggle(rdvs_user)
    tag.div(data: { toggle: "dropdown" },
            class: "dropdown-toggle btn btn-outline-rdv-status-#{rdvs_user.temporal_status}") do
      Rdv.human_attribute_value(:status, rdvs_user.temporal_status, disable_cast: true)
    end
  end

  def participation_delete_dropdown_item(rdvs_user, agent)
    link_to admin_organisation_rdv_participation_path(rdvs_user.rdv.organisation, rdvs_user.rdv, rdvs_user, agent_id: agent&.id),
            method: :delete,
            class: "dropdown-item",
            data: { confirm: t("admin.rdvs.delete.confirm") } do
      tag.div(t("helpers.delete"), class: "text-danger") +
        tag.div(t("admin.rdvs.delete.details"), class: "text-wrap text-muted")
    end
  end

end
