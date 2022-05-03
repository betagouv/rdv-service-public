# frozen_string_literal: true

class Agents::PlageOuvertureMailerPreview < ActionMailer::Preview
  delegate :plage_ouverture_created, :plage_ouverture_updated, :plage_ouverture_destroyed, to: :plage_ouverture_mailer

  private

  def plage_ouverture_mailer
    Agents::PlageOuvertureMailer.with(plage_ouverture: PlageOuverture.last)
  end
end
