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
    if @rdv.motif.by_phone
      message += "RDV Tél au #{@user.phone_number}.\n"
      #{Rails.application.routes.url_helpers.users_rdvs_url(host: ActionMailer::Base.default_url_options)}
    else
      message += "Adresse: #{@rdv.location}.\n"
    end
    message += "Infos et annulation: .\n"

    twilio_client = Twilio::REST::Client.new
    twilio_client.messages.create({
      from: @from,
      to: "+33658032519",
      body: message
    })
  end
end
