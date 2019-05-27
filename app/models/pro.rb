class Pro < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :async

  enum role: {user: 0, admin: 1}

  validates :email, :role, presence: true
  
  def initials
    "MM"
  end
end
