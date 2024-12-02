class ZoneImportForm
  include ActiveModel::Model

  attr_accessor :zones_file, :dry_run

  validates :zones_file, presence: true

  def initialize(attributes = {})
    attributes[:dry_run] = attributes[:dry_run] == "1" if attributes.key?(:dry_run)
    super
  end

  def save
    valid?
  end
end
