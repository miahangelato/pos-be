class AddServiceNameToActiveStorageBlobs < ActiveRecord::Migration[8.1]
  def change
    add_column :active_storage_blobs, :service_name, :string unless column_exists?(:active_storage_blobs, :service_name)
  end
end
