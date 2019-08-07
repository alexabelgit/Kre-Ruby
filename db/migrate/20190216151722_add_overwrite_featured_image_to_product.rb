class AddOverwriteFeaturedImageToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :overwrite_featured_image, :boolean, default: false
  end
end
