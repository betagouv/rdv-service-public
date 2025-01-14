class Admin::RdvWizardForm::Step4
  include Admin::RdvWizardFormConcern
  include Admin::RdvFormConcern

  def save
    result = valid? && rdv.save
    Notifiers::RdvCreated.perform_with(@rdv, @agent_author) if result
    result
  end

  def success_path
    if @rdv_plan_id
      rdv_plan = RdvPlan.find(@rdv_plan_id)
      rdv_plan.update!(rdv: rdv)
      admin_organisation_rdv_path(rdv.organisation, rdv)
    else
      admin_organisation_agent_agenda_path(
        rdv.organisation,
        agents.include?(@agent_author) ? @agent_author : agents.first,
        selected_event_id: rdv.id,
        date: starts_at.to_date
      )
    end
  end

  def success_flash
    if @rdv_plan_id
      rdv_plan = RdvPlan.find(@rdv_plan_id)
      message = "Le rendez-vous a été créé. <a href='#{rdv_plan.return_url}'>Retour vers Mon Suivi Social</a>"
    else
      message = I18n.t("admin.rdvs.message.success.create")
    end
    { flash: { success: message } }
  end
end
