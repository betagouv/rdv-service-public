# frozen_string_literal: true

class Admin::RdvCollectifSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :motif_id, :from_date, :with_availabilities
  attr_writer :from_date

  def motif
    organisation.motifs.find_by(id: motif_id)
  end

  def from_date=(date)
    @from_date = if date.is_a?(String)
                   DateTime.parse(date)
                 else
                   date
                 end
  rescue Date::Error
    Time.zone.today
  end
end
