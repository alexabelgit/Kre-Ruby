class ImportedQuestion < ApplicationRecord
  belongs_to :product
  belongs_to :customer

  delegate :store, to: :product
  delegate :display_name, :display_initials, :display_first_name, to: :customer

  enum status: [:pending, :published, :archived]

  scope :latest, -> { order(created_at: :desc) }

end
