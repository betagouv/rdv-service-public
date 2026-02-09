class PrescripteurMailer < ApplicationMailer
  include DateHelper
  helper MotifsHelper

  attr_reader :domain

  def rdv_created(participation, domain_id)
    @domain = Domain.find(domain_id)
    @prescripteur = participation.created_by
    @user = participation.user
    @rdv = participation.rdv
    mail(
      subject: I18n.t("prescripteurs_mailer.rdv_created.title", domain_name: @domain.name, date: relative_date(@rdv.starts_at)),
      to: participation.created_by.email
    )
  end
end
