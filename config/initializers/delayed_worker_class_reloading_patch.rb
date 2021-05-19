# frozen_string_literal: true

# This prevents high cpu usage by delayed_job in development, caused by constant reloading of the app.
# See https://github.com/collectiveidea/delayed_job/issues/821#issuecomment-259435251

module Delayed::WorkerClassReloadingPatch
  # Override Delayed::Worker#reserve_job to optionally reload classes before running a job
  def reserve_job(*)
    job = super

    if job && self.class.reload_app?
      if defined?(ActiveSupport::Reloader)
        Rails.application.reloader.reload!
      else
        ActionDispatch::Reloader.cleanup!
        ActionDispatch::Reloader.prepare!
      end
    end

    job
  end

  # Override Delayed::Worker#reload! which is called from the job polling loop to not reload classes
  def reload!
    # no-op
  end
end

Delayed::Worker.prepend Delayed::WorkerClassReloadingPatch if Rails.env.development?
