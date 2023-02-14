# frozen_string_literal: true

class MigrateRdvCoStatus < ActiveRecord::Migration[7.0]
  def change
    # Change invalid collectives rdv statuses noshow and excused (approx 500 rdvs in production)
    # This will set collectives rdv statuses to seen (if one or more participation is seen)
    # This will set collectives rdv statuses to revoked (if no participation is seen or unknown)
    Rdv.collectif.where(status: "noshow").map(&:update_rdv_status_from_participation)
    Rdv.collectif.where(status: "excused").map(&:update_rdv_status_from_participation)

    # We set restants collective rdvs statuses to 'unknown'
    Rdv.collectif.where(status: "noshow").each { |rdv| rdv.update!(status: "unknown") }
    Rdv.collectif.where(status: "excused").each { |rdv| rdv.update!(status: "unknown") }
  end
end
