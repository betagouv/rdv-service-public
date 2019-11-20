class TwilioTextMessenger
  attr_reader :user, :rdv, :from

  def initialize(rdv, user)
    @user = user
    @rdv = rdv
    @from = "+15005550006"
  end

  def send
    twilio_client = Twilio::REST::Client.new
    begin
      twilio_client.messages.create(
        from: @from,
        to: @user.formated_phone,
        body: rdv_created_content
      )
    rescue StandardError
      return false
    end
  end

  def rdv_created_content
    message = "RDV Solidarités - Bonjour,\n"
    message += "RDV #{@rdv.motif.name} #{I18n.l(@rdv.starts_at, format: :human)} (durée : #{@rdv.duration_in_min} minutes) a été confirmé.\n"
    message + if @rdv.motif.by_phone
                "RDV Tél au #{@user.phone_number}.\n"
              else
                "Adresse: #{@rdv.location}.\n"
              end
  end
end
