class Merchant < ApplicationRecord
  include Authorizable
  
  # Authentication
  has_secure_password

  # Enums
  # Rails 8.1 enum maps symbol keys to string values in database
  # When we write role: :customer, it stores 'CUSTOMER' in DB
  # When we read from DB, 'CUSTOMER' maps back to :customer symbol
  enum :role, { customer: 'CUSTOMER', merchant: 'MERCHANT', admin: 'ADMIN' }, default: :merchant

  # Associations
  # Categories are no longer scoped directly on the categories table.
  # A category can be shared across merchants; to get the categories
  # belonging to a merchant we go through products which carry the
  # merchant_id. Use distinct to avoid duplicates when multiple
  # products reference the same category.
  has_many :products, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :vouchers, dependent: :destroy
  has_many :shipping_methods, dependent: :destroy
  has_many :payment_methods, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :active, inclusion: { in: [true, false] }
  validates :password, presence: true, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  validates :role, presence: true, inclusion: { in: roles.keys.map(&:to_s) }
end
