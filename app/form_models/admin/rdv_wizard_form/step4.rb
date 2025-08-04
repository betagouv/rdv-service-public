class Admin::RdvWizardForm::Step4
  include Admin::RdvWizardFormConcern
  include Admin::RdvFormConcern

  def save
    result = valid? && rdv.save
    Notifiers::RdvCreated.perform_with(@rdv, @agent_author) if result
    result
  end

  def success_path
    admin_organisation_planning_agenda_path(
      rdv.organisation,
      agent_id: agents.include?(@agent_author) ? @agent_author.id : agents.first.id,
      selected_event_id: rdv.id,
      date: starts_at.to_date
    )
  end

  def success_flash
    { flash: { success: I18n.t("admin.rdvs.message.success.create") } }
  end
end
