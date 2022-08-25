# frozen_string_literal: true

class PaperTrailAugmentedVersion
  # PaperTrailAugmentedVersion is a presenter for PaperTrail::Version, that adds support for changes on additional “virtual attributes”.
  # TODO: We probably should customize PaperTrail (see https://github.com/paper-trail-gem/paper_trail#6c-custom-object-changes) instead of this.
  def self.for_resource(resource)
    # returns an array of augmented versions
    versions = resource.versions
    versions = versions.includes(:item) unless Rails.env.test? # versions is (a proxy to) an ActiveRecord::Relation, but in tests we mock it with a regular array
    versions.each_with_index.map do |version, idx|
      previous_version = idx >= 1 ? versions[idx - 1] : nil
      PaperTrailAugmentedVersion.new(version, previous_version)
    end
  end

  attr_reader :version

  delegate :created_at, :whodunnit, to: :version

  def initialize(version, previous_version)
    @version = version
    @previous_version = previous_version
  end

  IGNORED_ATTRIBUTES = %w[id updated_at encrypted_password].freeze

  # territory est le territoire dans lequel on est en train de faire l'affichage
  def changes(territory = nil)
    @changes ||= begin
      c = @version.changeset.except(*IGNORED_ATTRIBUTES).to_h
      c = c.filter { |_attribute, change| change.first.present? || change.last.present? }
      c = c.merge(virtual_changes)
      allowed_attributes = @version.item.class.paper_trail_options[:only]
      c = c.slice(*allowed_attributes) if allowed_attributes.present?

      if territory
        c = c.select { |attribute, _| enabled_field?(attribute, territory) }
      end
      c
    end
  end

  def changes?
    changes.present?
  end

  private

  def enabled_field?(attribute_name, territory)
    toggle_name = Territory::SOCIAL_FIELD_TOGGLES.key(attribute_name.to_sym)

    # Les champs qui n'ont pas de toggle sont enabled
    return true unless toggle_name

    territory[toggle_name]
  end

  def virtual_changes
    virtual_changes_array.to_h do |property_name, new_value|
      [
        property_name,
        [previous_version_virtual_attributes[property_name], new_value],
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
