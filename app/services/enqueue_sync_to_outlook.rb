# frozen_string_literal: true

class EnqueueSyncToOutlook
  def self.run(agents_rdv)
    new(agents_rdv).run
  end

  def initialize(agents_rdv)
    @agents_rdv = agents_rdv
  end

  def run
    return unless @agents_rdv.agent_connected_to_outlook

    if (@agents_rdv.outlook_id && rdv.cancelled?) || rdv.soft_deleted? || @agents_rdv.id.nil? # deleted
      Outlook::DestroyEventJob.perform_later(@agents_rdv.outlook_id, @agents_rdv.agent)
    elsif @agents_rdv.outlook_id
      Outlook::UpdateEventJob.perform_later(@agents_rdv)
    else
      Outlook::CreateEventJob.perform_later(@agents_rdv)
    end
  end

  private

  def rdv
    @agents_rdv.rdv
  end
end
