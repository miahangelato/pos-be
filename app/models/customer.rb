class Customer < ApplicationRecord
  # Associations
  belongs_to :merchant
  has_many :orders, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: { scope: :merchant_id }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :mobile_number, presence: true, uniqueness: { scope: :merchant_id }
  validates :merchant_id, presence: true

  # Scopes
  scope :by_email, ->(email) { where('email ILIKE ?', "%#{email}%") }
  scope :by_mobile, ->(mobile) { where('mobile_number ILIKE ?', "%#{mobile}%") }

  # Callbacks
  before_validation :normalize_phone_number

  def full_name
    "#{first_name} #{last_name}"
  end

  def last_checkout_address
    orders.where.not(delivery_address_id: nil).order(created_at: :desc).first&.delivery_address
  end

  private

  def normalize_phone_number
    self.mobile_number = mobile_number&.gsub(/\D/, '')
  end
end
