class Admin::RdvUserPresenter
  attr_reader :rdv, :user

  delegate :starts_at, :organisation, to: :rdv

  def initialize(rdv, user)
    @rdv = rdv
    @user = user
  end

  def previous_rdvs_truncated
    previous_rdvs.limit(5)
  end

  def previous_rdvs_count
    previous_rdvs.count
  end

  private

  def previous_rdvs
    Rdv
      .with_user(user)
      .where(organisation: organisation)
      .where("starts_at < ?", starts_at)
      .order(starts_at: :desc)
  end
end
