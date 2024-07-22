class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include HumanAttributeValue
  include BenignErrors

  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(#{table_name}.name))")) }

  def new_and_blank?
    new_record? && attributes == self.class.new.attributes
  end

  # Allows combining structurally different queries using subqueries.
  # The resulting query looks like this:
  #     SELECT * FROM table
  #     WHERE `table.deleted_at` IS NULL -- conditions previously defined on self
  #     AND
  #       (
  #         `table.id` IN (SELECT... first subquery)
  #         OR
  #         `table.id` IN (SELECT... second subquery)
  #         OR
  #         ...
  #       ) -- subqueries combined with OR
  #
  # It can be useful when merging scopes with different join tables:
  #     agents_with_open_plage = Agent.joins(:plage_ouvertures).merge(PlageOuverture.bookable_by_everyone)
  #     agents_with_open_rdv_collectif = Agent.joins(:rdvs).merge(Rdv.collectif)
  #     Agent.where_id_in_subqueries([agents_with_open_plage, agents_with_open_rdv_collectif])
  #
  def self.where_id_in_subqueries(subqueries)
    subqueries.map { |scope| where(id: scope) }.reduce(:or)
  end
end
