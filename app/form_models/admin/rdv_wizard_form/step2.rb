# frozen_string_literal: true

class Admin::RdvWizardForm::Step2
  include Admin::RdvWizardFormConcern
  validates :users, presence: true
  validate :phone_number_present_for_motif_by_phone

  def phone_number_present_for_motif_by_phone
    return unless rdv.motif.phone?

    users_to_notify = users.map(&:user_to_notify)
    errors.add(:base, I18n.t("activerecord.attributes.rdv.phone_number_missing")) if users_to_notify.none?{ _1.phone_number.present? }
  end

  def success_path
    new_admin_organisation_rdv_wizard_step_path(@organisation, step: 3, **to_query)
  end
end
