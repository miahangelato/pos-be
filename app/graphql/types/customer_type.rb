module Types
  class CustomerType < Types::BaseObject
    description "Customer"

    field :id, ID, null: false
    field :email, String, null: false
    field :first_name, String, null: false
    field :last_name, String, null: false
    field :full_name, String, null: false
    field :mobile_number, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :merchant, Types::MerchantType, null: false
    field :orders, [Types::OrderType], null: false
  end
end