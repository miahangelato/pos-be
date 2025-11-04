class CreateVouchers < ActiveRecord::Migration[8.1]
  def change
    create_table :vouchers do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :code
      t.decimal :discount_percentage
      t.decimal :discount_amount
      t.integer :max_uses
      t.integer :current_uses
      t.boolean :active
      t.datetime :expires_at

      t.timestamps
    end
  end
end
