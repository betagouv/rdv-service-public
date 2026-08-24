class Notifiers::RdvCollectifParticipations < BaseService
  def initialize(rdv, author, previous_participations)
    @rdv = rdv
    @author = author
    @previous_participations = previous_participations
  end

  def perform
    # This is the historical way to notify participations changes
    # when rdv is updated by the agent with participations add/remove in the updatable concern
    return if @rdv.starts_at < Time.zone.now

    Notifiers::RdvCreated.new(@rdv, @author, new_participants_to_notify).notify_users
  end

  private

  def new_participations
    current_participations.where.not(user_id: @previous_participations.map(&:user_id))
  end

  def new_participants_to_notify
    new_participations.select(&:not_cancelled?).select(&:send_lifecycle_notifications).map(&:user)
  end

  def current_participations
    @rdv.participations
  end
end
