class TwilioTextMessenger
  attr_reader :user, :rdv, :from

  def initialize(rdv, user)
    @user = user
    @rdv = rdv
    @from = ENV["TWILIO_PHONE_NUMBER"]
  end

  def send
    twilio_client = Twilio::REST::Client.new
    begin
      twilio_client.messages.create(
        from: @from,
        to: @user.formated_phone,
        body: rdv_created_content
      )
    rescue StandardError => e
      return e
    end
  end

  def rdv_created_content
    message = "RDV Solidarités - Bonjour,\n"
    message += "RDV #{@rdv.motif.name} #{I18n.l(@rdv.starts_at, format: :human)} a été confirmé.\n"
    message += if @rdv.motif.by_phone
                 "RDV Téléphonique.\n"
               else
                 "Adresse: #{@rdv.location}.\n"
               end
    message += "Infos et annulation: #{@rdv.organisation.phone_number}" if @rdv.organisation.phone_number
    message
  end
end
