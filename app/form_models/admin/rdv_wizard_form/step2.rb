class Admin::RdvWizardForm::Step2
  include Admin::RdvWizardFormConcern
  validates :users, presence: true, unless: -> { rdv.collectif? }
  validate :phone_number_present_for_motif_by_phone
  validate :can_receive_notification_for_motif_by_visio

  def phone_number_present_for_motif_by_phone
    return unless rdv.motif.phone?

    return if users.map(&:user_to_notify).any? { _1.phone_number.present? }

    errors.add :base, "Aucun usager n’a de numéro de téléphone renseigné alors que le rendez-vous est téléphonique"
  end

  def can_receive_notification_for_motif_by_visio
    return unless rdv.motif.visio?

    can_receive_notifications = users.map(&:user_to_notify).any? do |user|
      user.valid_email? ||
        (user.phone_number.present? && PhoneNumberValidation.number_is_mobile?(user.phone_number))
    end
    return if can_receive_notifications

    errors.add(:base, :missing_mobile_phone_or_email)
  end

  def success_path
    new_admin_organisation_rdv_wizard_step_path(@organisation, step: 3, **to_query)
  end
end
