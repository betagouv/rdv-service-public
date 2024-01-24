class SplitTerritory
  def initialize(territory_id, medsoc_referente_id)
    @territory_id = territory_id
    @medsoc_referente_id = medsoc_referente_id
  end

  def split!
    territory_attrbiutes
    new_territory = Territory.create(or)
  end

  private

  def original_territory
    @original_territory ||= Territory.find(@territory_id)
  end
end
