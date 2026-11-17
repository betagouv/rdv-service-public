class Agents::OutlookSyncMailer < ApplicationMailer
  default to: -> { @agent.email }

  def sync_disabled
    @agent = params[:agent]
    @error_description = params[:error_description]
    @error_uri = params[:error_uri]
    mail(subject: "Votre synchronisation Outlook a été désactivée")
  end

  private

  def domain
    @agent.domain
  end
end
