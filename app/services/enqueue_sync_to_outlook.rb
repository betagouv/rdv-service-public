# frozen_string_literal: true

class EnqueueSyncToOutlook
  def self.run(agents_rdv)
    new(agents_rdv).run
  end

  def initialize(agents_rdv_id, outlook_event_id)
    @agents_rdv_id = agents_rdv_id
    @outlook_event_id = outlook_event_id
  end

  # TODO: replace this by enqueuing directly a generic job, and determine the kind of sync needed at job runtime
  # this would avoid errors in case of race condition when an update and destroy job are executed out of order
  def run
    return unless @agents_rdv.agent_connected_to_outlook?

    if event_should_be_in_outlook?
      Outlook::CreateOrUpdateEventJob.perform_later(@agents_rdv)
    elsif @agents_rdv.outlook_id
      Outlook::DestroyEventJob.perform_later(@agents_rdv.outlook_id, @agents_rdv.agent)
    end
  end

  private

  def agents_rdv
    @agents_rdv ||= AgentsRdv.find_by_id(@agents_rdv_id)
  end

  def event_should_be_in_outlook?
    rdv_is_not_cancelled_or_deleted? && !@agents_rdv.destroyed?
  end

  def rdv_is_not_cancelled_or_deleted?
    !rdv.cancelled? && !rdv.soft_deleted? && !rdv.destroyed?
  end

  def rdv
    @agents_rdv.rdv
  end
end
