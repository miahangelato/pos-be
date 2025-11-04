class CreatePaymentProofs < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_proofs do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.string :file_key, null: false
      t.string :status, default: 'PENDING'
      t.integer :merchant_id
      t.text :remarks
      t.timestamp :verified_at
      t.timestamps
    end
    
    add_index :payment_proofs, :status
  end
end
