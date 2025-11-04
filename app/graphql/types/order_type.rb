module Types
  class OrderType < Types::BaseObject
    description "Order"

    field :id, ID, null: false
    field :reference_number, String, null: false
    field :order_type, String, null: false
    field :status, String, null: false
    field :payment_status, String, null: false
    field :payment_method, String, null: false
    field :shipping_method, String, null: true
    field :subtotal, Float, null: false
    field :delivery_fee, Float, null: false, method: :shipping_fee
    field :shipping_fee, Float, null: false  # Alias for frontend compatibility
    field :convenience_fee, Float, null: false
    field :discount_amount, Float, null: true, method: :voucher_discount
    field :grand_total, Float, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :customer, Types::CustomerType, null: false
    field :merchant, Types::MerchantType, null: false
    field :order_items, [Types::OrderItemType], null: false
    field :delivery_address, Types::DeliveryAddressType, null: true
    field :payment_proof, Types::PaymentProofType, null: true
  end
end