# frozen_string_literal: true

class MigrateRdvCoStatus < ActiveRecord::Migration[7.0]
  def change
    # Change invalid collectives rdv statuses noshow and excused (approx 500 rdvs in production)
    # This will set collectives rdv statuses to seen (if one or more participation is seen)
    # This will set collectives rdv statuses to revoked (if no participation is seen or unknown)
    Rdv.collectif.where(status: "noshow").each do |rdv|
      if rdv.rdvs_users.any?(&:seen?)
        rdv.update_column(:status, "seen")
        next
      end
      if rdv.rdvs_users.none?(&:seen?) && rdv.rdvs_users.none?(&:unknown?)
        rdv.update_columns(status: "revoked", cancelled_at: Time.zone.now)
      end
    end

    Rdv.collectif.where(status: "excused").each do |rdv|
      if rdv.rdvs_users.any?(&:seen?)
        rdv.update_column(:status, "seen")
        next
      end
      if rdv.rdvs_users.none?(&:seen?) && rdv.rdvs_users.none?(&:unknown?)
        rdv.update_columns(status: "revoked", cancelled_at: Time.zone.now)
      end
    end
  end
end
