class Organisation < ApplicationRecord
  include Rails.application.routes.url_helpers
  has_paper_trail
  has_many :lieux, dependent: :destroy
  has_many :motifs, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :rdvs, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_and_belongs_to_many :agents, -> { distinct }
  has_and_belongs_to_many :users, -> { distinct }

  validates :name, presence: true, uniqueness: true
  validates :departement, presence: true, length: { is: 2 }
  validates :phone_number, phone: { allow_blank: true }

  after_create :notify_admin

  def home_path(agent)
    if recent?
      organisation_setup_checklist_path(self)
    else
      organisation_agent_path(self, agent)
    end
  end

  def notify_admin
    Admins::OrganisationMailer.new_organisation(agents.first).deliver_later if agents.present?
  end

  def recent?
    1.week.ago < created_at
  end
end
