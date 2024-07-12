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
    subject = if @rdv.collectif?
                if @author.is_a?(Prescripteur)
                  @user = @author.user
                end
                t("agents.rdv_mailer.rdv_created.title_participation", domain_name: domain.name, date: relative_date(@rdv.starts_at))
              else
                t("agents.rdv_mailer.rdv_created.title", domain_name: domain.name, date: relative_date(@rdv.starts_at))
              end
    mail(subject: subject)
  end

  def rdv_cancelled(old_starts_at: nil)
    date = relative_date(old_starts_at || @rdv.starts_at)
    self.ics_payload = @rdv.payload(:destroy, @agent)
    subject = if @rdv.collectif?
                t("agents.rdv_mailer.rdv_cancelled.title_participation", domain_name: domain.name, date: date)
              else
                t("agents.rdv_mailer.rdv_cancelled.title", domain_name: domain.name, date: date)
              end
    mail(subject: subject)
  end

  def rdv_updated(old_starts_at:, lieu_id:)
    @old_starts_at = old_starts_at
    @address_name = Lieu.find(lieu_id).full_name if lieu_id

    self.ics_payload = @rdv.payload(:update, @agent)
    subject = t("agents.rdv_mailer.rdv_updated.title", date: relative_date(@old_starts_at))
    mail(subject: subject)
  end

  private

  def domain
    @agent.domain
  end
end
