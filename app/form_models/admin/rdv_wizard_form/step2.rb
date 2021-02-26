class Admin::RdvWizardForm::Step2
  include Admin::RdvWizardFormConcern
  validates :users, presence: true
  validate :phone_number_present_for_motif_by_phone

  def phone_number_present_for_motif_by_phone
    errors.add(:base, I18n.t("activerecord.attributes.rdv.phone_number_missing")) if rdv.motif.phone? && users.all? { _1.phone_number.blank? }
  end

  def success_path
    new_admin_organisation_rdv_wizard_step_path(@organisation, step: 3, **to_query)
  end
end
