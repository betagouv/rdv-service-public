# On reproduit le même principe que celui utilisé pour Outlook, mais pour Caldav
# Voir app/models/concerns/outlook/event_serializer_and_listener.rb
module Rdv::CaldavConcern
  extend ActiveSupport::Concern

  included do
    attr_accessor :needs_sync_to_caldav

    delegate :caldav_configured?, to: :agent, prefix: true

    AgentsRdv.before_commit do |agents_rdv|
      Rdv::CaldavConcern.mark_for_sync([agents_rdv])
    end
    Rdv.before_commit do |rdv|
      Rdv::CaldavConcern.mark_for_sync(rdv.agents_rdvs)
    end
    Participation.before_commit do |participation|
      Rdv::CaldavConcern.mark_for_sync(participation.rdv.agents_rdvs)
    end

    AgentsRdv.after_commit do |agents_rdv|
      Rdv::CaldavConcern.enqueue_sync_for_marked_records([agents_rdv])
    end
    Rdv.after_commit do |rdv|
      Rdv::CaldavConcern.enqueue_sync_for_marked_records(rdv.agents_rdvs)
    end
    Participation.after_commit do |participation|
      Rdv::CaldavConcern.enqueue_sync_for_marked_records(participation.rdv.agents_rdvs)
    end
  end

  def self.mark_for_sync(agents_rdvs)
    agents_rdvs.select(&:agent_caldav_configured?).each do |agents_rdv|
      agents_rdv.needs_sync_to_caldav = true
    end
  end

  def self.enqueue_sync_for_marked_records(agents_rdvs)
    agents_rdvs.select(&:needs_sync_to_caldav).each do |agents_rdv|
      Caldav::ExportRdvToCaldavJob.perform_later(agents_rdv.id, agents_rdv.agent_id, caldav_event_url: agents_rdv.caldav_url)
      agents_rdv.needs_sync_to_caldav = false
    end
  end
end
