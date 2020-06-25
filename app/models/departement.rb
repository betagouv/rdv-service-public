class Departement
  # NOTE : this is not an AR object just yet

  attr_accessor :number

  alias id number # useful to use with routes helpers
  alias to_s number

  def initialize(number)
    @number = number
  end
end
