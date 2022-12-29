# frozen_string_literal: true

class Users::RdvSms < Users::BaseSms
  include Rails.application.routes.url_helpers

  def rdv_title(rdv)
    if rdv.collectif? && rdv.name.present?
      "#{rdv.motif.service.short_name} : #{rdv.name},"
    else
      rdv.motif.service.short_name
    end
  end

  def rdv_created(rdv, user, token)
    @content = "RDV #{rdv_title(rdv)} #{starts_at(rdv)}.\n#{rdv_footer(rdv, user, token)}"
  end

  def rdv_updated(rdv, user, token)
    @content = "RDV modifié: #{rdv_title(rdv)} #{starts_at(rdv)}\n#{rdv_footer(rdv, user, token)}"
  end

  def rdv_upcoming_reminder(rdv, user, token)
    @content = "Rappel RDV #{rdv_title(rdv)} le #{starts_at(rdv)}.\n#{rdv_footer(rdv, user, token)}"
  end

  def rdv_cancelled(rdv, _user, token)
    base_message = "RDV #{rdv_title(rdv)} #{I18n.l(rdv.starts_at, format: :short)} a été annulé."
    url = prendre_rdv_short_url(host: domain_host, tkn: token)

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

  def rdv_footer(rdv, user, token)
    details = rdv_location(rdv)

    if user.relatives.present? && !rdv.collectif?
      users_full_names = rdv.users.map(&:full_name).sort.to_sentence
      details += " pour #{users_full_names}"
    end

    agents_short_names = rdv.agents.map(&:short_name).sort.to_sentence
    details += " avec #{agents_short_names}" if rdv.follow_up?

    details += ".\n"

    url = rdv_short_url(rdv, host: domain_host, tkn: token)
    links = "Infos et annulation: #{url}"

    links += " / #{rdv.phone_number}" if rdv.phone_number.present?

    details + links
  end

  def rdv_location(rdv)
    if rdv.phone?
      "RDV téléphonique"
    elsif rdv.home?
      "RDV à votre domicile"
    else
      rdv.address_complete
    end
  end
end
