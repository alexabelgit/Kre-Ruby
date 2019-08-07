class AddPricingModeToPlan < ActiveRecord::Migration[5.2]
  def up
    execute <<-DDL
    DROP TYPE IF EXISTS pricing_model;
    CREATE TYPE pricing_model AS ENUM (
      'products', 'orders'
    );
    DDL

    add_column :plans, :pricing_model, :pricing_model
    add_column :plans, :product_limits, :numrange
  end

  def down
    remove_column :plans, :pricing_model
    remove_column :plans, :product_limits
  end
end
