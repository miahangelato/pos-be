class AddImageDataToModels < ActiveRecord::Migration[8.1]
  def change
    # Add binary image data columns
    add_column :products, :image_data, :binary
    add_column :products, :image_filename, :string
    add_column :products, :image_content_type, :string
    
    add_column :payment_proofs, :image_data, :binary
    add_column :payment_proofs, :image_filename, :string
    add_column :payment_proofs, :image_content_type, :string
  end
end
