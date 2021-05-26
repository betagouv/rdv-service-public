# frozen_string_literal: true

class Admin::RdvUserPresenter
  PREVIOUS_RDVS_LIMIT = 5

  attr_reader :rdv, :user

  delegate :starts_at, :organisation, to: :rdv

  def initialize(rdv, user)
    @rdv = rdv
    @user = user
  end

  def previous_rdvs_truncated
    previous_rdvs.limit(PREVIOUS_RDVS_LIMIT)
  end

  delegate :count, to: :previous_rdvs, prefix: true

  def previous_rdvs_more?
    previous_rdvs_count > PREVIOUS_RDVS_LIMIT
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
