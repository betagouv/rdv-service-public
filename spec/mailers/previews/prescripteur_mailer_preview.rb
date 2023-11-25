class PrescripteurMailerPreview < ActionMailer::Preview
  def rdv_created
    PrescripteurMailer.rdv_created(Rdv.last.participations.first, Rdv.last.domain.id)
  end
end
