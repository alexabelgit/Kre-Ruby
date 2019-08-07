class ImportedReview < ApplicationRecord
  belongs_to :product, optional: true
  belongs_to :customer

  delegate :store, to: :customer
  delegate :display_logo, to: :store
  delegate :display_name, :display_initials, :display_first_name, to: :customer

  validates_inclusion_of :rating, in: 1..5
  validates_presence_of  :feedback
  validates_length_of    :feedback, minimum: 1, maximum: 6000

  enum status: [:pending, :published, :archived, :suppressed]

  scope :latest, -> { order(created_at: :desc) }

  has_many :media, -> { order(media_type: :desc, created_at: :asc) }, as: :mediable, dependent: :destroy
end
