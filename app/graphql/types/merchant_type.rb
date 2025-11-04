# frozen_string_literal: true

module Types
  class MerchantType < Types::BaseObject
    field :id, ID, null: false, description: "Unique identifier"
    field :name, String, null: false, description: "Merchant name"
    field :email, String, null: false, description: "Merchant email"
    field :active, Boolean, null: false, description: "Is merchant active"
    field :role, String, null: false, description: "Merchant role (MERCHANT or ADMIN)"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Created at timestamp"
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Updated at timestamp"

    # For frontend
    field :full_name, String, null: false, description: "Full name (same as name)"

    def full_name
      object.name
    end
  end
end
