class AddCloudinaryPublicIdToMedium < ActiveRecord::Migration[5.0]
  def change
    add_column :media, :cloudinary_public_id, :string
  end
end
