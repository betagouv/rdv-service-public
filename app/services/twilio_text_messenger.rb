class TwilioTextMessenger
  include Rails.application.routes.url_helpers

  attr_reader :user, :rdv, :from, :type

  def initialize(type, rdv, user)
    @type = type
    @user = user
    @rdv = rdv
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
    "RDV Solidarités - Bonjour,\n"
  end

  def sms_footer
    message = if @rdv.motif.by_phone
                "RDV Téléphonique.\n"
              else
                "Adresse: #{@rdv.location}.\n"
              end
    message += "Infos et annulation: #{rdvs_shorten_url(host: "http://#{ENV["HOST"]}")} "
    message += " / #{@rdv.organisation.phone_number}" if @rdv.organisation.phone_number
    message
  end

  def rdv_created
    message = sms_header
    message += "RDV #{@rdv.motif.name} - #{@rdv.motif.service.name} #{I18n.l(@rdv.starts_at, format: :human)} a été confirmé.\n"
    message += sms_footer
    message
  end

  def reminder
    message = sms_header
    message += "Rappel de votre RDV #{@rdv.motif.name} - #{@rdv.motif.service.name}, demain à #{@rdv.starts_at.strftime("%H:%M")}.\n"
    message += sms_footer
    message
  end
end
