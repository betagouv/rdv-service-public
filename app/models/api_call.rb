class ApiCall < ApplicationRecord
  belongs_to :agent

  after_initialize :set_received_at

  private

  def set_received_at
    self.received_at ||= Time.zone.now
  end
end
