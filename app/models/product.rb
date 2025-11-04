class Product < ApplicationRecord
  # Associations
  belongs_to :merchant
  belongs_to :category
  has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items
  has_one_attached :image

  # Enums

  enum :product_type, { physical: 'PHYSICAL', digital: 'DIGITAL' }

  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  # product_type is an enum with keys 'physical' and 'digital'.
  # Validate against the enum keys so the attribute value (which
  # returns the key name) is accepted.
  validates :product_type, presence: true, inclusion: { in: product_types.keys }
  validates :merchant_id, presence: true
  validate :image_type, :image_size

  # Scopes
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :search, ->(query) { where('name ILIKE ? OR description ILIKE ?', "%#{query}%", "%#{query}%") }
  scope :physical, -> { where(product_type: 'PHYSICAL') }
  scope :digital, -> { where(product_type: 'DIGITAL') }

  # Methods to get image URL
  def image_url
    if image.attached?
      Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
    end
  end

  private

  def image_type
    if image.attached? && !image.content_type.in?(%w(image/jpeg image/png image/gif image/webp))
      errors.add(:image, 'must be a JPEG, PNG, GIF, or WebP')
    end
  end

  def image_size
    if image.attached? && image.blob.byte_size > 5.megabytes
      errors.add(:image, 'is too large (max 5MB)')
    end
  end
end
