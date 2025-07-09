class Users::DemandesSupportMailer < ApplicationMailer
  def conversation_created
    @sujet = params[:demande_support_sujet]
    @message = params[:demande_support_message]
    mail(
      from: "#{domain} <#{domain.support_email.gsub('support@', 'assistance@')}>",
      to: params[:email],
      subject: params[:subject],
      "In-Reply-To" => params[:in_reply_to]
    )
  end

  private

  def domain
    Domain.find(params[:domain_id])
  end
end
