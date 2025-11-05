class PaymentProof < ApplicationRecord
  belongs_to :order
  has_one_attached :image
  
  validates :order_id, uniqueness: true
  
  enum :status, { pending: 'PENDING', verified: 'VERIFIED', rejected: 'REJECTED' }

  # Database image support for production deployment
  def attach_image_from_data(file_data, filename, content_type)
    self.image_data = file_data
    self.image_filename = filename
    self.image_content_type = content_type
  end

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
end
