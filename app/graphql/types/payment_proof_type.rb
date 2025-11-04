module Types
  class PaymentProofType < Types::BaseObject
    description "Payment proof"

    field :id, ID, null: false
    field :status, String, null: false
    field :file_key, String, null: true, description: "Legacy file key (deprecated)"
    field :image_url, String, null: true, description: "Payment proof image URL"
    field :remarks, String, null: true
    field :verified_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Custom field to get image URL (same pattern as ProductType)
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
  end
end