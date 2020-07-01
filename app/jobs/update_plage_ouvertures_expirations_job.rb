class UpdatePlageOuverturesExpirationsJob < ApplicationJob
  def perform
    PlageOuverture.where(expired_cached: false).each do |po|
      po.update(expired_cached: true) if po.expired?
    end
  end
end
