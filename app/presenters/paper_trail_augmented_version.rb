# frozen_string_literal: true

class PaperTrailAugmentedVersion
  def self.for_resource(resource, **kwargs)
    # returns an array of augmented versions
    versions = resource.versions
    versions = versions.includes(:item) unless Rails.env.test? # versions is (a proxy to) an ActiveRecord::Relation, but in tests we mock it with a regular array
    versions.each_with_index.map do |version, idx|
      previous_version = idx >= 1 ? versions[idx - 1] : nil
      PaperTrailAugmentedVersion.new(version, previous_version, **kwargs)
    end
  end

  attr_reader :version

  delegate :created_at, :whodunnit, to: :version

  def initialize(version, previous_version, attributes_allowlist: nil)
    @version = version
    @previous_version = previous_version
    @attributes_allowlist = attributes_allowlist
  end

  IGNORED_ATTRIBUTES = %w[id updated_at encrypted_password].freeze
  def changes
    @changes ||= begin
      c = @version.changeset.except(*IGNORED_ATTRIBUTES).to_h
      c = c.filter { |_attribute, change| change.first.present? || change.last.present? }
      c = c.merge(virtual_changes)
      c = c.slice(*@attributes_allowlist) unless @attributes_allowlist.nil?
      c
    end
  end

  def changes?
    changes.present?
  end

  private

  def virtual_changes
    virtual_changes_array.to_h do |property_name, new_value|
      [
        property_name,
        [previous_version_virtual_attributes[property_name], new_value]
      ]
    end
  end

  def virtual_changes_array
    @version.virtual_attributes.to_a - previous_version_virtual_attributes.to_a
  end

  def previous_version_virtual_attributes
    @previous_version_virtual_attributes ||=
      @previous_version&.virtual_attributes || {}
  end
end
