module Types
  class DeliveryAddressInputType < Types::BaseInputObject
    description "Attributes for delivery address"

    argument :province, String, required: true
    argument :city, String, required: true
    argument :barangay, String, required: true
    argument :street, String, required: true
    argument :unit_floor, String, required: false
    argument :building_name, String, required: false
    argument :landmark, String, required: false
    argument :remarks, String, required: false
  end
end