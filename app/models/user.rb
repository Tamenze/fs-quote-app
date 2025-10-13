class User < ApplicationRecord
  has_secure_password

  has_many :quotes
  has_many :created_tags, class_name: "Tag", foreign_key: "created_by_id"

  before_validation do 
    self.email = email.to_s.strip.downcase
    self.username = username.to_s.strip
  end 

  VALID_EMAIL = /\A[^@\s]+@[^@\s]+\z/
  validates :email, presence: true, 
                    uniqueness: { case_sensitive: false },
                    format: { with: VALID_EMAIL }
  validates :username, presence: true, 
                        uniqueness: { case_sensitive: false },
                        length: { minimum: 2, maximum: 32 }

  validates :password, length: { minimum: 8 }
  # , allow_nil: true

end
