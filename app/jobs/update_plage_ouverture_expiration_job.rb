class UpdatePlageOuvertureExpirationJob < ApplicationJob
  def perform()
    today = Date.today
    PlageOuverture.where(expired: false).each do |po|
      po.update(expired: true) if (po.recurrence.nil? && po.first_day < today) && (po.recurrence.present? && po.recurrence.until < today)
    end
  end
end
