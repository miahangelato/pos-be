class PaymentProof < ApplicationRecord
  belongs_to :order
  has_one_attached :image
  
  validates :order_id, uniqueness: true
  
  enum :status, { pending: 'PENDING', verified: 'VERIFIED', rejected: 'REJECTED' }
end
