class Rdv::UpdateStatusAndNotify
  def initialize(rdv, author, status:)
    @rdv = rdv
    @author = author
    @status = status
  end

  def perform
    Rdv.transaction do
      @rdv.status = @status
      @rdv.updated_at = Time.zone.now

      # On utilise #compact_blank pour faire une copie des participations qui ne sera pas modifiée pendant le #reload plus bas
      previous_participations = @rdv.participations.compact_blank

      if @rdv.status_changed? && @rdv.valid?
        @rdv.cancelled_at = @rdv.status.in?(%w[excused revoked noshow]) ? Time.zone.now : nil
        change_participation_statuses
        @rdv.participations.reload # reload is needed after .persisted? method call
      end

      if @rdv.save
        if @rdv.status.in?(Rdv::CANCELLED_STATUSES)
          @rdv.file_attentes.destroy_all
          @notifier = new_cancelled_notifier(@author, previous_participations)
        elsif rdv_status_reloaded_from_cancelled?
          @notifier = Notifiers::RdvCreated.new(@rdv, @author)
        end

        @notifier&.perform

        true
      else
        raise ActiveRecord::Rollback
      end
    end
  end

  def participation_token_for(user_id)
    @notifier.participations_tokens_by_user_id[user_id]
  end

  private

  def change_participation_statuses
    case @rdv.status
    when "unknown"
      # Setting to unknown means resetting the rdv status by agents and reset ALL participations statuses
      @rdv.participations.each { _1.update!(status: @rdv.status) }
    when "revoked", "excused"
      # When rdv status is revoked/excused, not cancelled participations are updated to revoked/excused
      # Collectives RDV status cannot be excused (validations)
      @rdv.participations.not_cancelled.each { _1.update!(status: @rdv.status) }
    when "seen", "noshow"
      # When rdv status is seen/noshow, unknowns participations statuses are updated to seen/noshow
      # Collectives RDV status cannot be noshow (validations)
      @rdv.participations.unknown.each { _1.update!(status: @rdv.status) }
    end
  end

  def new_cancelled_notifier(author, previous_participations)
    # Don't notify RDV cancellation to users that had previously cancelled their individual participation
    available_users_for_notif = previous_participations.select(&:send_lifecycle_notifications?).select(&:not_cancelled?).map(&:user)
    Notifiers::RdvCancelled.new(@rdv, author, available_users_for_notif)
  end

  def rdv_status_reloaded_from_cancelled?
    @rdv.status_previously_was.in?(Rdv::CANCELLED_STATUSES) && @rdv.status == "unknown"
  end
end
