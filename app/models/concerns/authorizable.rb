module Authorizable
  extend ActiveSupport::Concern

  included do
    # Role checking methods
    # Note: enum converts DB values ('CUSTOMER') to lowercase keys ('customer')
    def admin?
      role == 'admin'
    end

    def merchant?
      role == 'merchant' || admin? # Admins have merchant permissions too
    end

    def customer?
      role == 'customer'
    end

    # Permission checks
    def can_manage_merchants?
      admin?
    end

    def can_manage_products?
      merchant?
    end

    def can_create_orders?
      true # Everyone (customers, merchants, admins) can create orders
    end

    def can_manage_orders?
      merchant?
    end

    def can_manage_customers?
      merchant?
    end

    def can_view_own_orders?
      customer? || merchant?
    end

    def can_view_all_orders?
      admin?
    end

    def can_configure_shipping?
      admin?
    end

    def can_configure_payments?
      admin?
    end

    def can_access_reports?
      admin?
    end

    def can_access_dashboard?
      merchant? # Merchants and admins can access dashboard, customers cannot
    end

    def can_manage_categories?
      merchant?
    end
  end
end
