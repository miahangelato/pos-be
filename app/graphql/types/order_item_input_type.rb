module Types
  class OrderItemInputType < Types::BaseInputObject
    description "Attributes for order items"

    argument :product_id, ID, required: true
    argument :quantity, Integer, required: true
  end
end