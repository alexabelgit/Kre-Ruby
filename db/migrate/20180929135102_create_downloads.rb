class CreateDownloads < ActiveRecord::Migration[5.2]
  def change
    create_table :downloads do |t|
      t.text :name
      t.text :path
      t.text :url
      t.datetime :expired_at
      t.text :filetype
      t.integer :status

      t.references :store, index: true
      t.timestamps
    end
  end
end
