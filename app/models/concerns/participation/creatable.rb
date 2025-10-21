module Participation::Creatable
  extend ActiveSupport::Concern

  def create_and_notify!(author)
    Participation.transaction do
      empty_rdv_from_relatives
      save!
      user.add_organisation(organisation)
      Notifiers::ParticipationCreated.perform_with(participation: self, author:)
    end
  end

  private

  def empty_rdv_from_relatives
    # Empty self_and_relatives participations (at the moment, only one member by family), no callbacks, no notifications
    rdv.participations.where(user: user.self_and_relatives_and_responsible).delete_all
    rdv.participations.where(user: user.responsible&.self_and_relatives_and_responsible).delete_all
  end
end
