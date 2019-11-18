class TwilioTextMessenger
  attr_reader :user, :message

  def initialize(user, message)
    @user = user
    @message = "coucou"
    @from = "+15005550006"
  end

  def rdv_created
    twilio_client = Twilio::REST::Client.new
    twilio_client.messages.create({
      from: @from,
      to: "+33658032519",
      body: @message
    })
  end

end
