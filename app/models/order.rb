class Order < ApplicationRecord
  # Associations
  belongs_to :merchant
  belongs_to :customer
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_one :delivery_address, dependent: :destroy
  has_one :payment_proof, dependent: :destroy

  # Enums
  enum :order_type, { online: 'ONLINE', in_store: 'IN_STORE' }
  enum :status, { pending: 'PENDING', confirmed: 'CONFIRMED', out_for_delivery: 'OUT_FOR_DELIVERY', completed: 'COMPLETED', cancelled: 'CANCELLED' }
  enum :payment_status, { payment_pending: 'PAYMENT_PENDING', paid: 'PAID', failed_payment: 'FAILED' }
  enum :payment_method, { cash: 'CASH', gcash: 'GCASH' }

  # Validations
  validates :reference_number, uniqueness: { scope: :merchant_id }, allow_nil: true
  validates :order_type, presence: true
  validates :status, presence: true
  validates :payment_status, presence: true
  validates :payment_method, presence: true
  validates :shipping_method, presence: true, if: :online_order?
  validates :subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :grand_total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :merchant_id, presence: true
  validates :customer_id, presence: true

  # Callbacks
  before_create :generate_reference_number
  after_create :calculate_totals

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }
  scope :pending, -> { where(status: 'PENDING') }
  scope :out_for_delivery, -> { where(status: 'OUT_FOR_DELIVERY') }
  scope :completed, -> { where(status: 'COMPLETED') }

  private

  def generate_reference_number
    self.reference_number = "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def calculate_totals
    # Totals will be calculated by service
  end

  def online_order?
    order_type == 'ONLINE'
  end
end
