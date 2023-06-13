# frozen_string_literal: true

class Agents::PlageOuvertureMailer < ApplicationMailer
  helper MotifsHelper
  helper PlageOuverturesHelper

  before_action do
    @plage_ouverture = params[:plage_ouverture]
  end

  default to: -> { @plage_ouverture.agent.email }

  def plage_ouverture_created
    self.ics_payload = @plage_ouverture.payload(:create)
    mail(subject: t("agents.plage_ouverture_mailer.plage_ouverture_created.title", domain_name: domain.name, title: @plage_ouverture.title))
  end

  def plage_ouverture_updated
    self.ics_payload = @plage_ouverture.payload(:update)
    mail(subject: t("agents.plage_ouverture_mailer.plage_ouverture_updated.title", domain_name: domain.name, title: @plage_ouverture.title))
  end

  def plage_ouverture_destroyed
    self.ics_payload = @plage_ouverture.payload(:destroy)
    mail(subject: t("agents.plage_ouverture_mailer.plage_ouverture_destroyed.title", domain_name: domain.name, title: @plage_ouverture.title))
  end

  private

  def domain
    @plage_ouverture.agent.domain
  end

  def default_from
    domain.secretariat_email
  end
end
