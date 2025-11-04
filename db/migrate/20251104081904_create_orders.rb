class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :merchant, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :reference_number
      t.string :order_type
      t.string :status
      t.decimal :subtotal
      t.decimal :shipping_fee
      t.decimal :convenience_fee
      t.decimal :voucher_discount
      t.decimal :grand_total
      t.string :payment_method
      t.string :shipping_method
      t.string :payment_status

      t.timestamps
    end
  end
end
