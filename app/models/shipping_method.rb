class ShippingMethod < ApplicationRecord
  # Associations
  belongs_to :merchant

  # Enums
  enum calculation_type: { flat: 'FLAT', weight_based: 'WEIGHT_BASED', distance_based: 'DISTANCE_BASED' }

  # Validations
  validates :name, presence: true, uniqueness: { scope: :merchant_id }
  validates :base_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :calculation_type, presence: true, inclusion: { in: %w(FLAT WEIGHT_BASED DISTANCE_BASED) }
  validates :enabled, inclusion: { in: [true, false] }
  validates :merchant_id, presence: true

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :by_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }
end
