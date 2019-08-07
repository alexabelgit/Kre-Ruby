class AddIndexToMedia < ActiveRecord::Migration[5.2]
  def change
    add_index :media, :mediable_id
    add_index :media, [:mediable_id, :mediable_type, :status, :media_type], name: 'index_published_media_of_review', where: '(status = 1)'
  end
end
