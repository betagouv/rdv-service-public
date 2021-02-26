class Admin::RdvWizardForm::Step1
  include Admin::RdvWizardConcern
  validates :motif, :organisation, presence: true

  def success_path
    new_admin_organisation_rdv_wizard_step_path(@organisation, step: 2, **to_query)
  end
end
