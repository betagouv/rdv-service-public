class Agents::CaldavSyncMailer < ApplicationMailer
  default to: -> { @agent.email }

  def sync_disabled_incompatible_server
    @agent = params[:agent]
    mail(subject: "Votre synchronisation CalDAV a été supprimée")
  end

  private

  def domain
    @agent.domain
  end
end
