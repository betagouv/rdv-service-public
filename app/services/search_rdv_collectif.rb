# frozen_string_literal: true

module SearchRdvCollectif
  class << self
    def next_availability_for_lieu(motif, lieu, user = nil)
      next_availability = rdvs_collectif_at(motif, lieu, user).first
      OpenStruct.new(lieu: lieu, next_availability: next_availability)
    end

    def starts_at_for_first(rdvs)
      return nil if rdvs.empty?

      rdvs.first.starts_at
    end

    def rdvs_collectif_at(motif, lieu, user = nil)
      collective_rdvs = available_slots(motif, lieu)
      collective_rdvs = collective_rdvs.reject { |c| (c.rdvs_users.map(&:user_id) & user.self_and_relatives.map(&:id)).any? } if user.present?
      collective_rdvs
    end

    def available_slots(motif, lieu)
      Rdv.collectif_and_available_for_reservation
        .where(motif_id: motif.id)
        .where(lieu_id: lieu.id)
        .where("starts_at > ?", Time.zone.now + motif.min_public_booking_delay.seconds)
        .where("starts_at < ?", Time.zone.now + motif.max_public_booking_delay.seconds)
        .order(:starts_at)
    end

    alias creneaux available_slots
  end
end
