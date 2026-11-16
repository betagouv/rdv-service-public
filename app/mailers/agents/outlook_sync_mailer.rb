class Agents::OutlookSyncMailer < ApplicationMailer
  before_action do
    @agent = params[:agent]
    @error_description = params[:error_description]
  end

  default to: -> { @agent.email }

  def sync_disabled
    mail(subject: "Votre synchronisation Outlook a été désactivée")
  end

  private

  def domain
    @agent.domain
  end
end
