module RdvSpecHelper
  def create_rdv_skip_notify(**kwargs)
    rdv = build(:rdv, **kwargs)
    rdv.define_singleton_method(:notify_rdv_created, -> {})
    rdv.save!
    rdv
  end

  def update_rdv_skip_notify!(rdv, **kwargs)
    rdv.define_singleton_method(:notify_rdv_date_updated, -> {})
    rdv.update!(**kwargs)
  end
end
