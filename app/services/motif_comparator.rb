class MotifComparator
  TECHNICAL_ATTRIBUTES = %i[
    id
    organisation_id
    created_at
    updated_at
  ].to_set.freeze

  def initialize(motif_a, motif_b)
    @motif_a = motif_a
    @motif_b = motif_b
  end

  def strictly_identical?
    differences.none?
  end

  def differences
    hash = {}

    @motif_a.attributes.map do |attr, value_for_a|
      value_for_b = @motif_b.attributes.fetch(attr)
      if attr_is_different?(attr, @motif_a, @motif_b)
        hash[attr] = [value_for_a, value_for_b]
      end
    end

    hash.symbolize_keys
  end

  def attr_is_different?(attr_name, motif_a, motif_b)
    case attr_name.to_sym
    when *TECHNICAL_ATTRIBUTES
      false
    when :name
      motif_a.name_with_location_type != motif_b.name_with_location_type
    else
      motif_a.send(attr_name) != motif_b.send(attr_name)
    end
  end
end
