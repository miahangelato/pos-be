class Product < ApplicationRecord
  # Associations
  belongs_to :merchant
  belongs_to :category
  has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items
  has_one_attached :image

  # Database image support for production deployment
  def attach_image_from_data(file_data, filename, content_type)
    self.image_data = file_data
    self.image_filename = filename
    self.image_content_type = content_type
  end

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
    if image_data.present?
      # Database storage - return data URL for production
      # Use strict_encode64 to avoid newlines in the base64 string
      "data:#{image_content_type};base64,#{Base64.strict_encode64(image_data)}"
    elsif image.attached?
      # Active Storage - for development  
      Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
    end
  end

  def has_image?
    image_data.present? || image.attached?
  end

  private

  def image_type
    if image_content_type.present? && !image_content_type.in?(%w(image/jpeg image/png image/gif image/webp))
      errors.add(:image, 'must be a JPEG, PNG, GIF, or WebP')
    elsif image.attached? && !image.content_type.in?(%w(image/jpeg image/png image/gif image/webp))
      errors.add(:image, 'must be a JPEG, PNG, GIF, or WebP')
    end
  end

  def image_size
    if image_data.present? && image_data.bytesize > 5.megabytes
      errors.add(:image, 'is too large (max 5MB)')
    elsif image.attached? && image.blob.byte_size > 5.megabytes
      errors.add(:image, 'is too large (max 5MB)')
    end
  end
end
