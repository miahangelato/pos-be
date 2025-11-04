class AddRoleToMerchants < ActiveRecord::Migration[8.1]
  def change
    add_column :merchants, :role, :string, default: 'MERCHANT', null: false
  end
end
