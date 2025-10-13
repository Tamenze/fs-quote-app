class Tag < ApplicationRecord
  has_and_belongs_to_many :quotes

  # optional for cases where user gets deleted, tag should remain
  belongs_to :creator, class_name: "User", foreign_key: "created_by_id", optional: true 

  before_validation do
    #strip lead + trail whitespaces, replace remaining with underscore
    self.name = name.to_s.strip.squish.gsub(" ", "_")
  end 

  validates :name, presence: true, 
                    uniqueness: { case_sensitive: false },
                    length: { minimum: 2, maximum: 50 }

end
