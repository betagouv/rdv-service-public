# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true


  def self.human_enum_collection(enum_name)
    send(enum_name.to_s.pluralize).keys.collect { |val| [human_enum_name(enum_name, val), val] }
  end
  include HumanAttributeValue

  def new_and_blank?
    new_record? && attributes == self.class.new.attributes
  end
end
