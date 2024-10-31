module FuzzHelpers
  def random_value_in(array)
    array.sample(1, random: Random.new(RSpec.configuration.seed)).first
  end
end
