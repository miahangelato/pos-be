class MakePaymentProofFileKeyOptional < ActiveRecord::Migration[8.1]
  def change
    # Make file_key nullable since we're using Active Storage now
    change_column_null :payment_proofs, :file_key, true
  end
end
