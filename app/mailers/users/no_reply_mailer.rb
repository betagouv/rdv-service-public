class Users::NoReplyMailer < ApplicationMailer
  class UnrecognizableEmailAddressError < StandardError; end

  # @param [Mail::Message] source_mail : le mail initial envoyé par l’usager et transféré par Brevo à notre serveur
  def no_reply
    mail(
      from: no_reply_from,
      to: params[:source_mail].from.first,
      subject: "Mail non reçu"
    )
  end

  private

  def domain
    @domain ||= begin
      reply_email_domain = params[:source_mail].to.first.split("@").last
      case reply_email_domain
      when /rdv-solidarites/
        Domain::RDV_SOLIDARITES
      when /rdv-service-public/ || /rdv\.anct\.gouv/ || /rdv-mairie/
        Domain::RDV_MAIRIE
      when /rdv-aide-numerique/
        Domain::RDV_AIDE_NUMERIQUE
      else
        raise UnrecognizableEmailAddressError, params[:source_mail].to.to_s
      end
    end
  end
end
