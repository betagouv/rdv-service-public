require "administrate/field/base"

class SiretField < Administrate::Field::Base
  delegate :to_s, to: :data
end
