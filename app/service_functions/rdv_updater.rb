module RdvUpdater
  class << self
    def update_by_user(rdv, rdv_params)
      update(rdv, rdv_params, :user)
    end

    def update_by_agent(rdv, rdv_params)
      update(rdv, rdv_params, :agent)
    end

    private

    def update(rdv, rdv_params, by)
      rdv.updated_at = Time.zone.now
      # TODO: replace this manual touch. It forces creating a version when an
      # agent or a user is removed from the RDV. the touch: true option on the
      # association does not do it for some reason I could not figure out

      if rdv_params[:status].present?
        rdv_params[:cancelled_at] = cancel_status?(rdv_params[:status]) ? Time.zone.now : nil
      end

      return false unless rdv.update(rdv_params)

      rdv.file_attentes.destroy_all if cancel_status?(rdv_params[:status])
      notify(rdv, by) if rdv_params[:status] == "excused"
      true
    end

    def notify(rdv, by)
      send("notify_#{by}", rdv)
    end

    def notify_agent(rdv)
      Notifications::Rdv::RdvCancelledByAgent.perform_with(rdv)
    end

    def notify_user(rdv)
      Notifications::Rdv::RdvCancelledByUser.perform_with(rdv)
    end

    def cancel_status?(status)
      %w[excused notexcused].include?(status)
    end
  end
end
