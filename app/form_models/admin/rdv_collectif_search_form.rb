# frozen_string_literal: true

class Admin::RdvCollectifSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :motif_id, :with_remaining_seats

  def filter(rdvs)
    if motif_id.present?
      rdvs = rdvs.where(motif_id: motif_id)
    end

    if with_remaining_seats.to_bool
      rdvs = rdvs.with_remaining_seats
    end

    rdvs.where("starts_at >= ?", from_date)
  end

  def motif
    organisation.motifs.find_by(id: motif_id)
  end

  def from_date=(date)
    @from_date = date.is_a?(String) ? Time.zone.parse(date) : date
  rescue Date::Error
    Time.zone.today
  end

  def from_date
    @from_date.presence || Time.zone.now
  end
end
