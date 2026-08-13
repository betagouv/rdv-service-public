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

    Notifiers::RdvCancelled.new(@rdv, @author, removed_participants_to_notify).notify_users
  end

  private

  def new_participations
    current_participations.where.not(user_id: @previous_participations.map(&:user_id))
  end

  def new_participants_to_notify
    new_participations.select(&:not_cancelled?).select(&:send_lifecycle_notifications).map(&:user)
  end

  def removed_participations
    # Using the in-memory records instead of using SQL because
    # the previous participations have been removed from the DB
    @previous_participations.select { |p| !p.user_id.in?(current_participations.map(&:user_id)) } # rubocop:disable Style/InverseMethods
  end

  def removed_participants_to_notify
    # We do not notify already cancelled participations
    removed_participations.select(&:not_cancelled?).select(&:send_lifecycle_notifications).map(&:user)
  end

  def current_participations
    @rdv.participations
  end
end
