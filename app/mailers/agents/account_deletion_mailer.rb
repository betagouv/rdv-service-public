class Agents::AccountDeletionMailer < ApplicationMailer
  before_action do
    @agent = params[:agent]
  end

  default to: -> { @agent.email }

  def upcoming_deletion_warning
    mail(subject: "Votre compte sur #{domain.name} sera supprimé dans 1 mois", domain_name: domain.name)
  end

  private

  def domain
    @agent.domain
  end
end
