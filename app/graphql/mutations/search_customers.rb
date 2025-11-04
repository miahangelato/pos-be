module Mutations
  class SearchCustomers < BaseMutation
    description "Search customers by name, email, or mobile number"

    # Arguments
    argument :query, String, required: true
    argument :search_type, String, required: false

    # Return fields
    field :customers, [Types::CustomerType], null: false
    field :errors, [String], null: false

    def resolve(query:, search_type: nil)
      # Ensure user is authenticated
      current_user = context[:current_user]
      return { customers: [], errors: ["Authentication required"] } unless current_user

      begin
        customers = current_user.customers

        case search_type
        when 'email'
          customers = customers.by_email(query)
        when 'mobile'
          customers = customers.by_mobile(query)
        when 'name'
          customers = customers.where(
            "first_name ILIKE ? OR last_name ILIKE ?",
            "%#{query}%", "%#{query}%"
          )
        else
          # Search by first name, last name, email, and mobile number
          customers = customers.where(
            "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR mobile_number ILIKE ?",
            "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
          )
        end

        { customers: customers.limit(10), errors: [] }
      rescue => e
        { customers: [], errors: [e.message] }
      end
    end
  end
end