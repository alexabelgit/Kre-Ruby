class AddOriginalImageUrlToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :original_image_url, :text
  end
end
