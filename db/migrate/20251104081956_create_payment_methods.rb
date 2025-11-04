class CreatePaymentMethods < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_methods do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :name
      t.string :payment_type
      t.boolean :enabled

      t.timestamps
    end
  end
end
