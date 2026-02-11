class WebhookJob < ApplicationJob
  # TODO: Supprimer cette classe quand tous les jobs portant cet ancien nom de classe sont dépilés.
  # GoodJob::Job.where(job_class: "WebhookJob", finished_at: nil).count # => 0
  #
  def perform(payload, webhook_endpoint_id)
    # Pas la peine de ré-enqueue les jobs déjà bloqués en retry
    return if executions > 10

    WebhookSendJob.perform_later(payload, webhook_endpoint_id)
  end
end
