class CreateDeliveryAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_addresses do |t|
      t.references :order, null: false, foreign_key: true
      t.string :province
      t.string :city
      t.string :barangay
      t.string :street
      t.string :room_unit
      t.string :floor
      t.string :building
      t.string :landmark
      t.string :remarks

      t.timestamps
    end
  end
end
