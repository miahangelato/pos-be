module Types
  class CustomerInputType < Types::BaseInputObject
    description "Attributes for creating or updating a customer"

    argument :email, String, required: true
    argument :first_name, String, required: true
    argument :last_name, String, required: true
    argument :mobile_number, String, required: true
  end
end