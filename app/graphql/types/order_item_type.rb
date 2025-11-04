module Types
  class OrderItemType < Types::BaseObject
    description "Order Item"

    field :id, ID, null: false
    field :quantity, Integer, null: false
    field :unit_price, Float, null: false, method: :price_at_purchase
    field :price_at_purchase, Float, null: false  # Alias for frontend compatibility
    field :total_price, Float, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :product, Types::ProductType, null: false
    field :order, Types::OrderType, null: false

    def total_price
      object.quantity * object.price_at_purchase
    end
  end
end