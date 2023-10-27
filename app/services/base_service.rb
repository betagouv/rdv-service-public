class BaseService
  def self.perform_with(...)
    new(...).perform
  end

  def initialize(...); end # Make Rubymine Code Inspection happy
end
