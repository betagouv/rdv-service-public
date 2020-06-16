class Departement
  # NOTE : this is not an AR object just yet

  attr_accessor :number

  alias id number
  alias to_s number

  def initialize(number)
    @number = number
  end
end
