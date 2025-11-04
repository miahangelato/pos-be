module Types
  class DeliveryAddressType < Types::BaseObject
    description "Delivery Address"

    field :id, ID, null: false
    field :province, String, null: false
    field :city, String, null: false
    field :barangay, String, null: false
    field :street, String, null: false
    field :room_unit, String, null: true
    field :floor, String, null: true
    field :building, String, null: true
    field :unit_floor, String, null: true  # Alias for frontend compatibility
    field :building_name, String, null: true  # Alias for frontend compatibility
    field :landmark, String, null: true
    field :remarks, String, null: true
    field :full_address, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :order, Types::OrderType, null: false

    # Alias methods for frontend compatibility
    def unit_floor
      object.room_unit
    end

    def building_name
      object.building
    end

    def full_address
      parts = [
        object.room_unit,
        object.floor,
        object.building,
        object.street,
        object.barangay,
        object.city,
        object.province
      ].compact.reject(&:blank?)
      
      parts.join(", ")
    end
  end
end