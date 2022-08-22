# frozen_string_literal: true

class Agents::RdvMailer < ApplicationMailer
  include DateHelper
  helper DateHelper

  before_action do
    @rdv = params[:rdv]
    @agent = params[:agent]
    @author = params[:author]
  end

  default to: -> { @agent.email }

  def rdv_created
    self.ics_payload = @rdv.payload(:create, @agent)
    subject = t("agents.rdv_mailer.rdv_created.title", domain_name: domain.name, date: relative_date(@rdv.starts_at))
    mail(subject: subject)
  end

  def rdv_cancelled
    self.ics_payload = @rdv.payload(:destroy, @agent)
    subject = t("agents.rdv_mailer.rdv_cancelled.title", date: relative_date(@rdv.starts_at))
    mail(subject: subject)
  end

  def rdv_updated(starts_at:, lieu_id:)
    @starts_at = starts_at
    @address_name = Lieu.find(lieu_id).full_name

    self.ics_payload = @rdv.payload(:update, @agent)
    subject = t("agents.rdv_mailer.rdv_updated.title", date: relative_date(@starts_at))
    mail(subject: subject)
  end

  private

  def domain
    @agent.domain
  end
end
