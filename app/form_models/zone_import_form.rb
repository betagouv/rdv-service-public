class ZoneImportForm
  include ActiveModel::Model

  attr_accessor :zones_file, :dry_run, :override_conflicts

  validates :zones_file, presence: true

  def initialize(attributes = {})
    attributes[:dry_run] = attributes[:dry_run] == '1' if attributes.key?(:dry_run)
    attributes[:override_conflicts] = attributes[:override_conflicts] == '1' if attributes.key?(:override_conflicts)
    super(attributes)
  end

  def save
    valid?
  end
end
