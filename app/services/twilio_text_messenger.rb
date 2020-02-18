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
        body: body
      )
    rescue StandardError => e
      e
    end
  end

  private

  def sms_header
    "RDV Solidarités\n"
  end

  def sms_footer
    message = if @rdv.motif.by_phone
                "RDV Téléphonique\n"
              else
                "#{@rdv.location}\n"
              end
    message += "Infos et annulation: #{rdvs_shorten_url(host: "https://#{ENV["HOST"]}")} "
    message += " / #{@rdv.organisation.phone_number}" if @rdv.organisation.phone_number
    message
  end

  def rdv_created
    message = sms_header
    message += "RDV #{@rdv.motif.service.name} #{I18n.l(@rdv.starts_at, format: :short)}\n"
    message += sms_footer
    message
  end

  def reminder
    message = sms_header
    message += "Rappel RDV #{@rdv.motif.service.name} le #{I18n.localize(@rdv.starts_at.to_date, format: :short).strip} à #{@rdv.starts_at.strftime("%H:%M")}\n"
    message += sms_footer
    message
  end

  def file_attente
    message = "Des créneaux se sont libérés plus tôt.\n"
    message += "Cliquez pour voir les disponibilités : #{users_creneaux_index_url(rdv_id: @rdv.id, host: "https://#{ENV["HOST"]}")}"
    message
  end
end
