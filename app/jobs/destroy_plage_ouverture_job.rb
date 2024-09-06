class DestroyPlageOuvertureJob < ApplicationJob
  def perform(plage_ouverture_id)
    plage_ouverture = PlageOuverture.find_by(id: plage_ouverture_id)
    return unless plage_ouverture

    if plage_ouverture.agent.plage_ouverture_notification_level == "all"
      Absence.transaction do
        Agents::PlageOuvertureMailer.with(plage_ouverture: plage_ouverture).plage_ouverture_destroyed.deliver_now
        plage_ouverture.destroy!
      end
    else
      plage_ouverture.destroy!
    end
  end
end
