# frozen_string_literal: true

class AbsencesOrganisation < ApplicationRecord
  belongs_to :organisation
  belongs_to :absence
end
