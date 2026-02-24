class Tag < ApplicationRecord
  def self.normalize_name(s)
    # strip lead + trail whitespaces, replace remaining spaces with underscore
    s.to_s.strip.squish.gsub(" ", "_")
  end

  has_and_belongs_to_many :quotes


  # optional for cases where user gets deleted, tag should remain
  belongs_to :creator, class_name: "User", foreign_key: "created_by_id", optional: true

  before_validation do
    self.name = Tag.normalize_name(name)
  end

  validates :name, presence: true,
                    uniqueness: { case_sensitive: false },
                    length: { minimum: 2, maximum: 50 }
end
