# frozen_string_literal: true

class PrescripteurMailer < ApplicationMailer
  include DateHelper

  attr_reader :domain

  def rdv_created(rdv, domain_name)
    @domain = Domain.find_by_name(domain_name) # rubocop:disable

    mail(
      subject: I18n.t("prescripteurs_mailer.rdv_created.title", domain_name: @domain.name, date: relative_date(rdv.starts_at)),
      to: rdv.prescripteur.email
    )
  end
end
