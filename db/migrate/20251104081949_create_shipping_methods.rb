class CreateShippingMethods < ActiveRecord::Migration[8.1]
  def change
    create_table :shipping_methods do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :name
      t.decimal :base_fee
      t.string :calculation_type
      t.boolean :enabled

      t.timestamps
    end
  end
end
