# frozen_string_literal: true

class PrescripteurMailer < ApplicationMailer
  include DateHelper

  attr_reader :domain

  def rdv_created(rdvs_user, domain_id)
    @domain = Domain.find(domain_id)
    @user = rdvs_user.user
    @rdv = rdvs_user.rdv
    mail(
      subject: I18n.t("prescripteurs_mailer.rdv_created.title", domain_name: @domain.name, date: relative_date(@rdv.starts_at)),
      to: rdvs_user.prescripteur.email
    )
  end
end
