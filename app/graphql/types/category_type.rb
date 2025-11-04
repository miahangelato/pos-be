# frozen_string_literal: true

module Types
  class CategoryType < Types::BaseObject
    field :id, ID, null: false, description: "Unique identifier"
    field :name, String, null: false, description: "Category name"
  # Keep merchantId available for clients that still request it.
  # Categories are global in this app, so merchant_id will typically be nil.
  field :merchant_id, ID, null: true, description: "(Optional) Merchant ID - deprecated for global categories"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Created at timestamp"
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Updated at timestamp"
  end
end
