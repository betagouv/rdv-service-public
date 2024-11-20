class MotifsComparisonPresenter
  ATTR_NAMES = Motif.column_names - MotifComparator::TECHNICAL_ATTRIBUTES

  def initialize(org_a, org_b)
    @org_a = org_a
    @org_b = org_b
  end

  attr_reader :org_a, :org_b

  def motifs_grouped_by_duplicates
    (@org_a.motifs.active.to_a + @org_b.motifs.active.to_a).group_by do |motif|
      [motif.slugged_name, motif.service_id, motif.location_type]
    end.map do |_common, duplicates|
      raise "what?" if duplicates.size > 2

      duplicate_in_a = duplicates.find { _1.organisation == @org_a }
      duplicate_in_b = duplicates.find { _1.organisation == @org_b }

      [duplicate_in_a, duplicate_in_b]
    end
  end
end
