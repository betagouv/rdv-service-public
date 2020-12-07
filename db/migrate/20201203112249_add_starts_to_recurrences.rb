class AddStartsToRecurrences < ActiveRecord::Migration[6.0]
  def up
    PlageOuverture.where.not(recurrence: nil).find_each { update_model(_1) }
    Absence.where.not(recurrence: nil).find_each { update_model(_1) }
  end

  def down; end

  private

  def update_model(model)
    return if model.recurrence.to_h[:starts]&.present?

    model.update_columns(recurrence: model.recurrence.merge(starts: model.first_day.in_time_zone))
  end
end
