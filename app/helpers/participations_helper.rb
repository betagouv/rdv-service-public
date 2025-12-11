module ParticipationsHelper
  def participation_status_dropdown_toggle(participation)
    tag.div(data: { toggle: "dropdown" },
            class: "dropdown-toggle btn rdv-status-#{participation.temporal_status}") do
      Participation.human_attribute_value(:status, participation.temporal_status, disable_cast: true)
    end
  end

  def participation_delete_dropdown_item(participation)
    link_to admin_organisation_rdv_participation_path(participation.rdv.organisation, participation.rdv, participation, contextual_agent_ids: Current.last_selected_agent_ids&.map(&:id)),
            class: "dropdown-item",
            data: { turbo_method: :delete, confirm: t("admin.participations.delete.confirm") } do
      tag.div(t("admin.participations.delete.title"), class: "text-danger") +
        tag.div(t("admin.participations.delete.details"), class: "text-wrap text-muted")
    end
  end
end
