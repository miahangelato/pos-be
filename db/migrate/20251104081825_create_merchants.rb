class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants do |t|
      t.string :name
      t.string :email
      t.boolean :active

      t.timestamps
    end
  end
end
