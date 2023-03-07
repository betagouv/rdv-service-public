# frozen_string_literal: true

class EnqueueSyncToOutlook
  def self.run(agents_rdv)
    new(agents_rdv).run
  end

  def initialize(agents_rdv)
    @agents_rdv = agents_rdv
  end

  # TODO: just have all the job logic in this class (and turn it into a job)
  def run
    return unless @agents_rdv.agent_connected_to_outlook

    if rdv.cancelled? || rdv.soft_deleted? || @agents_rdv.id.nil? # deleted
      Outlook::DeleteEventJob.perform_later(@agents_rdv.outlook_id)
      Outlook::UpdateEventJob.perform_later(@agents_rdv)
    elsif @agents_rdv.exists_in_outlook?
      Outlook::UpdateEventJob.perform_later(@agents_rdv)
    else
      @agents_rdv.update(outlook_create_in_progress: true)
      Outlook::CreateEventJob.perform_later(@agents_rdv)
    end
  end

  private

  def rdv
    @agents_rdv.rdv
  end
end
