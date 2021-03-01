class Admin::RdvWizardForm::Step4
  include Admin::RdvWizardFormConcern
  include Admin::RdvFormConcern

  def save
    valid? && rdv.save
  end

  def success_path
    admin_organisation_agent_path(
      rdv.organisation,
      agents.include?(@agent_author) ? @agent_author : agents.first,
      selected_event_id: rdv.id,
      date: starts_at.to_date
    )
  end

  def success_flash
    { notice: "Le rendez-vous a été créé." }
  end
end
