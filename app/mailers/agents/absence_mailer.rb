# frozen_string_literal: true

class Agents::AbsenceMailer < ApplicationMailer
  helper PlageOuverturesHelper

  before_action do
    @absence = params[:absence]
  end

  default to: -> { @absence.agent.email }

  def absence_created
    self.ics_payload = @absence.payload(:created)
    mail(subject: t("agents.absence_mailer.absence_created.title", domain_name: domain.name, title: @absence.title))
  end

  def absence_updated
    self.ics_payload = @absence.payload(:updated)
    mail(subject: t("agents.absence_mailer.absence_updated.title", domain_name: domain.name, title: @absence.title))
  end

  def absence_destroyed
    self.ics_payload = @absence.payload(:destroy)
    mail(subject: t("agents.absence_mailer.absence_destroyed.title", domain_name: domain.name, title: @absence.title))
  end

  private

  def domain
    @absence.agent.domain
  end

  def default_from
    domain.secretariat_email
  end
end
