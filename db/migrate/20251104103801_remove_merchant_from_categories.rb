class RemoveMerchantFromCategories < ActiveRecord::Migration[8.1]
  def change
    remove_index :categories, :merchant_id
    remove_column :categories, :merchant_id
  end
end
