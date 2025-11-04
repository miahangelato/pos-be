class DeliveryAddress < ApplicationRecord
  # Associations
  belongs_to :order

  # Validations
  validates :province, presence: true
  validates :city, presence: true
  validates :barangay, presence: true
  validates :street, presence: true
  validates :order_id, presence: true

  def full_address
    address_parts = [room_unit, floor, building, street, barangay, city, province].compact
    address_parts.join(', ')
  end
end
