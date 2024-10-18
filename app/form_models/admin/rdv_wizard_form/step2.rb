class Admin::RdvWizardForm::Step2
  include Admin::RdvWizardFormConcern
  validates :users, presence: true, unless: -> { rdv.collectif? }
  validate :phone_number_present_for_motif_by_phone
  validate :can_receive_notification_for_motif_by_visio

  def phone_number_present_for_motif_by_phone
    return unless rdv.motif.phone?

    users_to_notify = users.map(&:user_to_notify)
    errors.add(:phone_number, :missing_for_phone_motif) if users_to_notify.none? { _1.phone_number.present? }
  end

  def can_receive_notification_for_motif_by_visio
    return unless rdv.motif.visio?

    can_receive_notifications = users.map(&:user_to_notify).any? do |user|
      user.email.present? ||
        (user.phone_number.present? && PhoneNumberValidation.number_is_mobile?(user.phone_number))
    end
    return if can_receive_notifications

    errors.add(:base, :missing_mobile_phone_or_email)
  end

  def success_path
    new_admin_organisation_rdv_wizard_step_path(@organisation, step: 3, **to_query)
  end
end
