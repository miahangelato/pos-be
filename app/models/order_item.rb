class OrderItem < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :product

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_at_purchase, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, presence: true

  # Scopes
  scope :by_order, ->(order_id) { where(order_id: order_id) }

  def line_total
    quantity * price_at_purchase
  end
end
