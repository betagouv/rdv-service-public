class TwilioTextMessenger
  include Rails.application.routes.url_helpers

  attr_reader :user, :rdv, :from, :type

  def initialize(type, rdv, user, options = {})
    @type = type
    @user = user
    @rdv = rdv
    @options = options
    @from = ENV["TWILIO_PHONE_NUMBER"]
  end

  def send_sms
    twilio_client = Twilio::REST::Client.new
    body = send(@type)
    begin
      twilio_client.messages.create(
        from: @from,
        to: @user.formated_phone,
        body: replace_special_chars(body)
      )
    rescue StandardError => e
      e
    end
  end

  private

  def replace_special_chars(body)
    body.tr('áâãëẽêíïîĩóôõúûũçÀÁÂÃÈËẼÊÌÍÏÎĨÒÓÔÕÙÚÛŨ', 'aaaeeeiiiiooouuucAAAAEEEEIIIIIOOOOUUUU')
  end

  def sms_footer
    message = if @rdv.motif.by_phone
                "RDV Téléphonique\n"
              else
                "#{@rdv.location}\n"
              end
    message += "Infos et annulation: #{rdvs_shorten_url(host: "https://#{ENV["HOST"]}")}"
    message += " / #{@rdv.organisation.phone_number}" if @rdv.organisation.phone_number
    message
  end

  def rdv_created
    message = "RDV #{@rdv.motif.service.short_name} #{I18n.l(@rdv.starts_at, format: :short)}\n"
    message += sms_footer
    message
  end

  def reminder
    message = "Rappel RDV #{@rdv.motif.service.short_name} le #{I18n.l(@rdv.starts_at.to_date, format: :short).strip} à #{@rdv.starts_at.strftime("%H:%M")}\n"
    message += sms_footer
    message
  end

  def file_attente
    message = "Un RDV #{@rdv.motif.name} - #{@rdv.motif.service.short_name} #{I18n.l(@rdv.starts_at, format: :human)} s'est libéré.\n"
    message += "Cliquez pour vérifier la disponibilité : #{edit_users_creneaux_url(rdv_id: @rdv.id, starts_at: @options[:creneau_starts_at].to_s, host: "https://#{ENV["HOST"]}")}"
    message
  end
end
