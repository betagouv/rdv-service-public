# frozen_string_literal: true

class PrescripteurMailerPreview < ActionMailer::Preview
  def rdv_created
    PrescripteurMailer.rdv_created(Rdv.last.rdvs_users.first, Rdv.last.domain.id)
  end
end
