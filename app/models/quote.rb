class Quote < ApplicationRecord
  # optional for cases where user gets deleted, quote should remain
  belongs_to :user, optional: true
  has_and_belongs_to_many :tags, -> { order(name: :asc) }

  before_validation do
    self.body = body.to_s
      .strip
      .gsub(/\A['"]+|['"]+\z/, "")  # remove leading/trailing ' or "
      .squish
    self.attribution = attribution.to_s.strip.squish
  end

  validates :body,
    presence: true,
    length: { maximum: 1_000 },
    uniqueness: { case_sensitive: false, message: "This quote has already been uploaded." }
  validates :attribution, presence: true, length: { maximum: 255 }
  validates :user_id, presence: true, on: :create
end
