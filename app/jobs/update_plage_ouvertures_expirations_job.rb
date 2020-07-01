class UpdatePlageOuverturesExpirationsJob < ApplicationJob
  def perform
    today = Date.today
    PlageOuverture.where(expired_cached: false).each do |po|
      po.update(expired_cached: true) if po.expired?
    end
  end
end
