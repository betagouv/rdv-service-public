# frozen_string_literal: true

module AgendaHelper
  def status_to_display(agent)
    if agent.display_cancelled_rdv
      nil
    else
      Rdv::NOT_CANCELLED_STATUSES
    end
  end
end
