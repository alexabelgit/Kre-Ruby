class RenameImageUrlToFeaturedImage < ActiveRecord::Migration[5.0]
  def change
    rename_column :products, :image_url, :featured_image
  end
end
