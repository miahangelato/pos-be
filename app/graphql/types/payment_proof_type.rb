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
      object.image_url
    end
  end
end