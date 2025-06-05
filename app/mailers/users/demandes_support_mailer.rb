class Users::DemandesSupportMailer < ApplicationMailer
  def conversation_created
    @conversation_id = params[:conversation_id]
    @sujet = params[:sujet]
    @message = params[:message]
    mail(
      from: domain.support_email,
      to: params[:email],
      subject: "[##{@conversation_id}] Nouveaux messages dans cette conversation"
    )
  end

  private

  def domain
    Domain.find(params[:domain])
  end
end
