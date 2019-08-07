class GenericFlags < ActiveRecord::Migration[5.0]
  def change

    add_column :flags, :flaggable_id, :integer
    add_column :flags, :flaggable_type, :string

    Flag.all.each do |flag|
      flag.flaggable = Review.find_by_id(flag.review_id)
      flag.save
    end

    remove_column :flags, :review_id

    change_column_null(:flags, :flaggable_id, false)
    change_column_null(:flags, :flaggable_type, false)

  end
end