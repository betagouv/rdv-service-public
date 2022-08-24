# frozen_string_literal: true

class Agents::AbsenceMailer < ApplicationMailer
  helper PlageOuverturesHelper

  before_action do
    @absence = params[:absence]
  end

  default from: "secretariat-auto@rdv-solidarites.fr",
          to: -> { @absence.agent.email }

  def absence_created
    self.ics_payload = @absence.payload(:created)
    mail(subject: t("agents.absence_mailer.absence_created.title", domain_name: domain.name, title: @absence.title))
  end

  def absence_updated
    self.ics_payload = @absence.payload(:updated)
    mail(subject: t("agents.absence_mailer.absence_updated.title", domain_name: domain.name, title: @absence.title))
  end

  def absence_destroyed
    self.ics_payload = @absence.payload(:destroyed)
    mail(subject: t("agents.absence_mailer.absence_destroyed.title", domain_name: domain.name, title: @absence.title))
  end

  private

  def domain
    @absence.agent.domain
  end
end
