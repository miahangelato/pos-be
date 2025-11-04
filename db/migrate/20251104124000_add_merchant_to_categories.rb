class AddMerchantToCategories < ActiveRecord::Migration[8.1]
  # Migration intentionally left as a no-op.
  # The project uses global categories (no merchant_id on categories),
  # so running this migration would fail because existing category
  # records don't have merchant_id. Keep the file so the migration
  # timestamp remains present but make it a harmless no-op so
  # Rails will mark it as applied during migrations without altering
  # the schema.
  def change
    # no-op
  end
end
