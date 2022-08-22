# frozen_string_literal: true

class Agents::PlageOuvertureMailer < ApplicationMailer
  helper MotifsHelper
  helper PlageOuverturesHelper

  before_action do
    @plage_ouverture = params[:plage_ouverture]
  end

  default from: "secretariat-auto@rdv-solidarites.fr",
          to: -> { @plage_ouverture.agent.email }

  def plage_ouverture_created
    self.ics_payload = @plage_ouverture.payload(:create)
    mail(subject: t("agents.plage_ouverture_mailer.plage_ouverture_created.title", title: @plage_ouverture.title))
  end

  def plage_ouverture_updated
    self.ics_payload = @plage_ouverture.payload(:update)
    mail(subject: t("agents.plage_ouverture_mailer.plage_ouverture_updated.title", title: @plage_ouverture.title))
  end

  def plage_ouverture_destroyed
    self.ics_payload = @plage_ouverture.payload(:destroy)
    mail(subject: t("agents.plage_ouverture_mailer.plage_ouverture_destroyed.title", title: @plage_ouverture.title))
  end
end
