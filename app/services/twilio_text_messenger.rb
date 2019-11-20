class TwilioTextMessenger
  attr_reader :user, :rdv, :from

  def initialize(user, rdv)
    @user = user
    @rdv = rdv
    @from = "+15005550006"
  end

  def rdv_created
    message = "RDV Solidarités - Bonjour,\n"
    message += "RDV #{@rdv.motif.name} #{I18n.l(@rdv.starts_at, format: :human)} (durée : #{@rdv.duration_in_min} minutes) a été confirmé.\n"
    message += if @rdv.motif.by_phone
                 "RDV Tél au #{@user.phone_number}.\n"
               else
                 "Adresse: #{@rdv.location}.\n"
               end

    twilio_client = Twilio::REST::Client.new
    twilio_client.messages.create(
      from: @from,
      to: user.phone_number,
      body: message
    )
  end
end
