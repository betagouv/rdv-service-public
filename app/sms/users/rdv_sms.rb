class Users::RdvSms < Users::BaseSms
  include Rails.application.routes.url_helpers
  extend ActionView::Helpers::TextHelper

  def rdv_title(rdv)
    if rdv.collectif? && rdv.name.present?
      [rdv.service_short_name, truncated_rdv_name].compact.join(" : ")
    else
      rdv.service_short_name
    end
  end

  def rdv_created(rdv, user, token)
    address_format = if @rdv.starts_at < 2.days.from_now
                       :full
                     else
                       :short
                     end

    @content = "RDV #{rdv_title(rdv)} #{starts_at(rdv)}.\n#{rdv_footer(rdv, user, token, address_format:)}"
  end

  def rdv_updated(rdv, user, token)
    address_format = if @rdv.starts_at < 2.days.from_now
                       :full
                     else
                       :short
                     end

    @content = "RDV modifié: #{rdv_title(rdv)} #{starts_at(rdv)}\n#{rdv_footer(rdv, user, token, address_format:)}"
  end

  def rdv_upcoming_reminder(rdv, user, token)
    @content = "RDV #{rdv_title(rdv)} #{starts_at(rdv)}\n#{rdv_footer(rdv, user, token, address_format: :full)}"
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

  MAX_RDV_NAME_LENGTH = 50

  def truncated_rdv_name
    "#{self.class.truncated_rdv_name(@rdv.name)},"
  end

  def self.truncated_rdv_name(name)
    omission_length = "...".length
    truncate(name, length: (MAX_RDV_NAME_LENGTH + omission_length))
  end

  private

  def starts_at(rdv)
    I18n.l(rdv.starts_at, format: rdv.home? ? :short_sms_approx : :short_sms)
  end

  def rdv_footer(rdv, user, token, address_format: :short)
    details = rdv_location(rdv, address_format:)

    if user.relatives.present? && !rdv.collectif?
      users_full_names = rdv.users.map(&:full_name).sort.to_sentence
      details += " pour #{users_full_names}"
    end

    agents_short_names = rdv.agents.map(&:short_name).sort.to_sentence
    details += " avec #{agents_short_names}" if rdv.follow_up?

    details += "\n\n"

    url = rdv_short_from_token_url(token, host: domain_host).sub(%r{https?://}, "")
    links = "Gérer mon RDV: #{url}"

    links += "\n#{rdv.phone_number}" if rdv.phone_number.present?

    details + links
  end

  def rdv_location(rdv, address_format: :short)
    case rdv.motif.location_type
    when "public_office"
      if address_format == :full
        rdv.full_address
      elsif address_format == :short
        rdv.address
      else
        raise "Format d'adresse inconnu : #{address_format}"
      end
    when "phone"
      "Par tél"
    when "home"
      "A domicile"
    when "visio"
      "Par visio"
    else
      raise "Il manque un texte de rdv_location pour #{rdv.motif.location_type}"
    end
  end
end
