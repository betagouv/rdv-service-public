# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include HumanAttributeValue
  include BenignErrors

  def new_and_blank?
    new_record? && attributes == self.class.new.attributes
  end
end
