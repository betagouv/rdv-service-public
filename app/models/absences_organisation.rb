# frozen_string_literal: true

class AbsencesOrganisation < ApplicationRecord
  belongs_to :organisation
  belongs_to :absence

  validate :absence_is_not_territory_wide

  private

  def absence_is_not_territory_wide
    errors.add(:absence, "is territory wide") if absence.territory_wide?
  end
end
