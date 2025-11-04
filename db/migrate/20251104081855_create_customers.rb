class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :mobile_number

      t.timestamps
    end
  end
end
