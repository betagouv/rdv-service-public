class MotifsComparisonPresenter
  # include ActiveModel::Model

  TECHNICAL_ATTRIBUTES = %w[
    id
    organisation_id
    created_at
    updated_at
  ].freeze

  IGNORED_ATTRIBUTES = %w[
    color
  ].freeze

  USER_BOOKING_ATTRIBUTES = %w[
    min_public_booking_delay
    max_public_booking_delay
    restriction_for_rdv
    instruction_for_rdv
    custom_cancel_warning_message
    rdvs_editable_by_user
    sectorisation_level
  ].freeze

  def self.attrs_names
    Motif.column_names - TECHNICAL_ATTRIBUTES
  end

  def initialize(org_a, org_b, show_all_attrs:, only_different_pairs:)
    @org_a = org_a
    @org_b = org_b
    @show_all_attrs = show_all_attrs
    @only_different_pairs = only_different_pairs
  end

  attr_reader :org_a, :org_b, :show_all_attrs, :only_different_pairs

  class Pair
    def initialize(motif_a, motif_b)
      @motif_a = motif_a
      @motif_b = motif_b
    end

    attr_reader :motif_a, :motif_b

    def mostly_identical?
      raise "can't tell if motifs are different because we only have one motif" if one_side?

      differences.none?
    end

    def one_side?
      !both_sides?
    end

    def differences
      hash = {}

      @motif_a.attributes.map do |attr, value_for_a|
        value_for_b = @motif_b.attributes.fetch(attr)
        if attr_is_different?(attr, @motif_a, @motif_b)
          hash[attr] = [value_for_a, value_for_b]
        end
      end

      hash
    end

    def attr_is_different?(attr_name, motif_a, motif_b)
      if attr_name.in?(USER_BOOKING_ATTRIBUTES)
        # Ne pas signaler l'attribut comme différent s'il concerne la résa usager
        # et qu'aucun des deux motifs n'est réservable par les usagers.
        return false if [motif_a, motif_b].none?(&:bookable_by_everyone_or_bookable_by_invited_users?)
      end
      return false if attr_name.in?(TECHNICAL_ATTRIBUTES + IGNORED_ATTRIBUTES)

      motif_a.send(attr_name) != motif_b.send(attr_name)
    end

    private

    def both_sides?
      @motif_a && @motif_b
    end
  end

  def displayed_pairs
    pairs
  end

  def pairs
    @pairs ||= (@org_a.motifs.active.to_a + @org_b.motifs.active.to_a).group_by do |motif|
      [motif.slugged_name, motif.service_id, motif.location_type]
    end.map do |_common_criteria, duplicates|
      raise "this should never happen, motifs are unique by name / service / location type / org" if duplicates.size > 2

      duplicate_in_a = duplicates.find { _1.organisation == @org_a }
      duplicate_in_b = duplicates.find { _1.organisation == @org_b }

      Pair.new(duplicate_in_a, duplicate_in_b)
    end
  end
end
