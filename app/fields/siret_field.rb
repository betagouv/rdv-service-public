require "administrate/field/base"

class SiretField < Administrate::Field::Base
  delegate :to_s, to: :data

  def self.searchable?
    true
  end
end
