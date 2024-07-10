class Admin::RdvWizardForm::Step3
  include Admin::RdvWizardFormConcern
  include Admin::RdvFormConcern

  validate -> { rdv.validate }

  def success_path
    new_admin_organisation_rdv_wizard_step_path(@organisation, step: 4, **to_query)
  end

  protected

  def agent_context
    AgentOrganisationContext.new(@agent_author, @organisation)
  end
end
