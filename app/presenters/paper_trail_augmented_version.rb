class PaperTrailAugmentedVersion
  def self.for_resource(resource, **kwargs)
    # returns an array of augmented versions
    versions = resource.versions
    versions.each_with_index.map do |version, idx|
      previous_version = idx >= 1 ? versions[idx - 1] : nil
      PaperTrailAugmentedVersion.new(version, previous_version, **kwargs)
    end
  end

  attr_reader :version
  delegate :created_at, :whodunnit, to: :version

  def initialize(version, previous_version, attributes_whitelist: nil)
    @version = version
    @previous_version = previous_version
    @attributes_whitelist = attributes_whitelist
  end

  def changes
    @changes ||= begin
      c = @version.changeset.except("updated_at").to_h.merge(virtual_changes)
      c = c.slice(*@attributes_whitelist) unless @attributes_whitelist.nil?
      c
    end
  end

  def changes?
    changes.present?
  end

  private

  def virtual_changes
    virtual_changes_array.map do |property_name, new_value|
      [
        property_name,
        [previous_version_virtual_attributes[property_name], new_value],
      ]
    end.to_h
  end

  def virtual_changes_array
    @version.virtual_attributes.to_a - previous_version_virtual_attributes.to_a
  end

  def previous_version_virtual_attributes
    @previous_version_virtual_attributes ||=
      @previous_version&.virtual_attributes || {}
  end
end
