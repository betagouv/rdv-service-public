class ProcessTerritoryCreationRequestForm
  include ActiveModel::Model

  def initialize(territory_creation_request)
    @territory_creation_request = territory_creation_request
  end

  delegate :organisation_name, :territory_name, to: :territory_creation_request
  attr_accessor :service_ids, :territory_creation_request

  def submit; end
end
