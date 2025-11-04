class PaymentMethod < ApplicationRecord
  # Associations
  belongs_to :merchant

  # Enums
  enum :payment_type, { cash: 'CASH', online: 'ONLINE', check: 'CHECK', bank_transfer: 'BANK_TRANSFER' }

  # Validations
  validates :name, presence: true, uniqueness: { scope: :merchant_id }
  validates :payment_type, presence: true, inclusion: { in: %w(CASH ONLINE CHECK BANK_TRANSFER) }
  validates :enabled, inclusion: { in: [true, false] }
  validates :merchant_id, presence: true

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :by_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }
  scope :online, -> { where(payment_type: 'ONLINE') }
  scope :offline, -> { where(payment_type: ['CASH', 'CHECK', 'BANK_TRANSFER']) }
end
