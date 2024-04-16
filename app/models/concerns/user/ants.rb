module User::Ants
  extend ActionView::Helpers::TranslationHelper # allows getting a SafeBuffer instead of a String when using #translate (which a direct call to I18n.t doesn't do)

  PRE_DEMANDE_NUMBER_FORMAT = /\A[A-Za-z0-9]{10}\z/

  def self.valid_pre_demande_number?(number)
    number.match?(PRE_DEMANDE_NUMBER_FORMAT)
  end

  def self.warning_message(appointment)
    translate(
      "activerecord.warnings.models.user.ants_pre_demande_number_already_used_html",
      management_url: appointment.management_url,
      meeting_point: appointment.meeting_point
    )
  end

  def self.error_message(status)
    case status
    when "consumed"
      "Ce numéro de pré-demande ANTS correspond à un dossier déjà instruit"
    when "unknown"
      "Ce numéro de pré-demande ANTS est inconnu"
    when "expired"
      "Ce numéro de pré-demande ANTS a expiré"
    else
      "Ce numéro de pré-demande ANTS est invalide"
    end
  end
end
