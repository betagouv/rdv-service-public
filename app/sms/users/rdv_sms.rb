# frozen_string_literal: true

class Users::RdvSms < Users::BaseSms
  include Rails.application.routes.url_helpers

  def rdv_created(rdv, user, token)
    @content = "RDV #{rdv.motif&.service&.short_name} #{starts_at(rdv)}.\n #{rdv_footer(rdv, user, token)}"
  end

  def rdv_date_updated(rdv, user, token)
    @content = "RDV modifié: #{rdv.motif.service.short_name} #{starts_at(rdv)}\n#{rdv_footer(rdv, user, token)}"
  end

  def rdv_upcoming_reminder(rdv, user, token)
    @content = "Rappel RDV #{rdv.motif.service.short_name} le #{starts_at(rdv)}.\n#{rdv_footer(rdv, user, token)}"
  end

  def rdv_cancelled(rdv, _user, token)
    base_message = "RDV #{rdv.motif.service.short_name} #{I18n.l(rdv.starts_at, format: :short)} a été annulé"
    url = prendre_rdv_url(host: ENV["HOST"], tkn: token)

    footer = if rdv.phone_number.present?
               "Appelez le #{rdv.phone_number} ou allez sur #{url} pour reprendre RDV."
             else
               "Allez sur #{url} pour reprendre RDV."
             end
    @content = "#{base_message}\n#{footer}"
  end

  private

  def starts_at(rdv)
    I18n.l(rdv.starts_at, format: rdv.home? ? :short_approx : :short)
  end

  def rdv_footer(rdv, user, token) # rubocop:disable Metrics/PerceivedComplexity
    message = if rdv.phone?
                "RDV Téléphonique\n"
              elsif rdv.home?
                "RDV à domicile\n#{rdv.address}\n"
              else
                "#{rdv.address_complete}\n"
              end
    if user.relatives.present?
      users_full_names = rdv.users.map(&:full_name).sort.to_sentence
      message += " pour #{users_full_names}"
    end

    agents_short_names = rdv.agents.map(&:short_name).sort.to_sentence
    message += " avec #{agents_short_names} " if rdv.follow_up?

    url = rdv_shorten_url(rdv, host: ENV["HOST"], tkn: token)
    message += "Infos et annulation: #{url}"

    message += " / #{rdv.phone_number}" if rdv.phone_number.present?
    message
  end
end
