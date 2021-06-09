# frozen_string_literal: true

class Agents::PlageOuvertureMailerPreview < ActionMailer::Preview
  def plage_ouverture_created
    plage_ouverture = PlageOuverture.last

    Agents::PlageOuvertureMailer.plage_ouverture_created(plage_ouverture.payload(:create))
  end

  def plage_ouverture_updated
    plage_ouverture = PlageOuverture.last
    Agents::PlageOuvertureMailer.plage_ouverture_updated(plage_ouverture.payload(:update))
  end

  def plage_ouverture_destroyed
    plage_ouverture = PlageOuverture.last
    Agents::PlageOuvertureMailer.plage_ouverture_destroyed(plage_ouverture.payload(:destroy))
  end
end
