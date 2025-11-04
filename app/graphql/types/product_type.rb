# frozen_string_literal: true

module Types
  class ProductType < Types::BaseObject
    field :id, ID, null: false, description: "Unique identifier"
    field :name, String, null: false, description: "Product name"
    field :description, String, null: true, description: "Product description"
    field :price, Float, null: false, description: "Product price"
    field :product_type, String, null: false, description: "Product type (PHYSICAL or DIGITAL)"
    field :stock_quantity, Integer, null: true, description: "Stock quantity for physical products"
    field :image_url, String, null: true, description: "Product image URL"
    field :category, Types::CategoryType, null: true, description: "Product category"
    field :merchant, Types::MerchantType, null: false, description: "Merchant who owns this product"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Created at timestamp"
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Updated at timestamp"

    # Custom field to get image URL
    def image_url
      # Return Active Storage attachment URL if image is attached
      if object.image.attached?
        # Generate a properly signed URL with expiration timestamp
        # This is required for Active Storage to serve the file
        blob = object.image.blob
        signed_id = blob.signed_id(expires_in: 1.day)
        filename = blob.filename
        # Return absolute URL pointing to backend server
        base_url = Rails.env.production? ? ENV['BACKEND_URL'] || 'https://your-api-domain.com' : 'http://localhost:3000'
        "#{base_url}/rails/active_storage/blobs/redirect/#{signed_id}/#{filename}"
      end
    end

    # Return the product_type as the canonical uppercase value (PHYSICAL/DIGITAL)
    # so clients that expect the uppercase representation continue to work.
    def product_type
      object.product_type&.upcase
    end
  end
end
