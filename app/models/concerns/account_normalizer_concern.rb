module AccountNormalizerConcern
  extend ActiveSupport::Concern

  def normalize_account
    email&.downcase!
    self.first_name = first_name.split("-").map(&:capitalize).join("-") if first_name
    last_name&.upcase!
    birth_name&.upcase! if defined?(birth_name)
  end
end
