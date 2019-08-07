class ProductsSyncBatch < ApplicationRecord
  belongs_to :store

  scope :unprocessed, -> { where(processed_at: nil)}

  def skip_image_update?
    arguments && arguments['skip_image_update']
  end

  def skip_reindex_children?
    arguments && arguments['skip_reindex_children?']
  end
end
