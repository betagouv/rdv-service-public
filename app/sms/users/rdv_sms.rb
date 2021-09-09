# frozen_string_literal: true

class Users::RdvSms < Users::BaseSms
  include Rails.application.routes.url_helpers

  def rdv_created(rdv_payload, _user)
    @content = "RDV #{rdv_payload[:motif_service_short_name]} #{starts_at(rdv_payload)}.\n #{rdv_footer(rdv_payload)}"
  end

  def rdv_date_updated(rdv_payload, _user)
    @content = "RDV modifié: #{rdv_payload[:motif_service_short_name]} #{starts_at(rdv_payload)}\n#{rdv_footer(rdv_payload)}"
  end

  def rdv_upcoming_reminder(rdv_payload, _user)
    @content = "Rappel RDV #{rdv_payload[:motif_service_short_name]} le #{starts_at(rdv_payload)}.\n#{rdv_footer(rdv_payload)}"
  end

  def rdv_cancelled(rdv_payload, _user)
    base_message = "RDV #{rdv_payload[:motif_service_short_name]} #{I18n.l(rdv_payload.starts_at, format: :short)} a été annulé"
    url = "https://rdv-solidarites.fr"
    footer = if rdv_payload[:phone_number].present?
      "Appelez le #{rdv_payload[:phone_number]} ou allez sur #{url} pour reprendre RDV."
    else
      "Allez sur #{url} pour reprendre RDV."
    end
    @content = "#{base_message}\n#{footer}"
  end

  private

  def starts_at(rdv_payload)
    I18n.l(rdv_payload[:starts_at], format: rdv_payload[:home?] ? :short_approx : :short)
  end

  def rdv_footer(rdv_payload)
    message = if rdv_payload[:phone?]
      "RDV Téléphonique\n"
    elsif rdv_payload[:home?]
      "RDV à domicile\n#{rdv_payload[:address]}\n"
    else
      "#{rdv_payload[:address_complete]}\n"
    end
    message += " pour #{rdv_payload[:users_full_names]}" if rdv_payload[:should_display_users_in_sms?]
    message += " avec #{rdv_payload[:agents_full_names]} " if rdv_payload[:follow_up?]
    message += "Infos et annulation: #{rdvs_shorten_url(host: ENV['HOST'])}"
    message += " / #{rdv_payload[:phone_number]}" if rdv_payload[:phone_number].present?
    message
  end
end
