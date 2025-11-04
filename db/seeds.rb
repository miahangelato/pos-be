# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create global product categories (idempotent)
category_names = [
  'Electronics',
  'Clothing',
  'Food & Beverages',
  'Home & Garden',
  'Sports & Outdoors',
  'Books & Media',
  'Toys & Games',
  'Beauty & Personal Care',
  'Health & Wellness',
  'Office Supplies'
]

category_names.each do |category_name|
  category = Category.find_or_create_by!(name: category_name)
  puts "Ensured category: #{category.name}"
end

puts "Seed data completed — ensured #{category_names.length} global categories exist."

# Create test merchants
test_merchants = [
  {
    name: 'John Doe',
    email: 'merchant@test.com',
    password: 'password123',
    role: 'MERCHANT',
    active: true
  },
  {
    name: 'Jane Smith (Admin)', 
    email: 'admin@posystem.com',
    password: 'admin123',
    role: 'ADMIN',
    active: true
  }
]

test_merchants.each do |merchant_data|
  merchant = Merchant.find_or_create_by!(email: merchant_data[:email]) do |m|
    m.name = merchant_data[:name]
    m.password = merchant_data[:password]
    m.role = merchant_data[:role]
    m.active = merchant_data[:active]
  end
  puts "Ensured test merchant: #{merchant.name} (#{merchant.email})"
  
  # Create sample products for each merchant
  if merchant.products.empty?
    electronics = Category.find_by(name: 'Electronics')
    clothing = Category.find_by(name: 'Clothing')
    food = Category.find_by(name: 'Food & Beverages')
    
    sample_products = [
      {
        name: 'iPhone 15 Pro',
        description: 'Latest iPhone with titanium design and A17 Pro chip',
        price: 59999.00,
        product_type: 'PHYSICAL',
        stock_quantity: 25,
        category: electronics,
        image_url: 'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=400&h=400&fit=crop'
      },
      {
        name: 'Samsung Galaxy S24',
        description: 'Premium Android smartphone with AI features',
        price: 54999.00,
        product_type: 'PHYSICAL', 
        stock_quantity: 18,
        category: electronics,
        image_url: 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=400&h=400&fit=crop'
      },
      {
        name: 'MacBook Air M3',
        description: '13-inch laptop with M3 chip',
        price: 65999.00,
        product_type: 'PHYSICAL',
        stock_quantity: 12,
        category: electronics,
        image_url: 'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=400&h=400&fit=crop'
      },
      {
        name: 'Premium Cotton T-Shirt',
        description: 'High-quality cotton t-shirt in various colors',
        price: 899.00,
        product_type: 'PHYSICAL',
        stock_quantity: 50,
        category: clothing,
        image_url: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop'
      },
      {
        name: 'Denim Jeans',
        description: 'Classic fit denim jeans',
        price: 2499.00,
        product_type: 'PHYSICAL',
        stock_quantity: 30,
        category: clothing,
        image_url: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&h=400&fit=crop'
      },
      {
        name: 'Coffee Beans - Premium Blend',
        description: 'Arabica coffee beans, freshly roasted',
        price: 450.00,
        product_type: 'PHYSICAL',
        stock_quantity: 100,
        category: food,
        image_url: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400&h=400&fit=crop'
      },
      {
        name: 'Digital Marketing Course',
        description: 'Complete digital marketing online course',
        price: 2999.00,
        product_type: 'DIGITAL',
        stock_quantity: nil,
        category: Category.find_by(name: 'Books & Media')
      },
      {
        name: 'Software License - Photo Editor',
        description: 'Professional photo editing software license',
        price: 1999.00,
        product_type: 'DIGITAL', 
        stock_quantity: nil,
        category: electronics
      }
    ]
    
    sample_products.each do |product_data|
      next unless product_data[:category] # Skip if category doesn't exist
      
      product = merchant.products.create!(
        name: product_data[:name],
        description: product_data[:description],
        price: product_data[:price],
        product_type: product_data[:product_type],
        stock_quantity: product_data[:stock_quantity],
        category: product_data[:category],
        image_url: product_data[:image_url]
      )
      puts "  Created sample product: #{product.name}"
    end
  end
  
  # Create sample customers for each merchant
  if merchant.customers.empty?
    sample_customers = [
      {
        email: 'customer1@test.com',
        first_name: 'Maria',
        last_name: 'Santos',
        mobile_number: '+639171234567'
      },
      {
        email: 'customer2@test.com', 
        first_name: 'Juan',
        last_name: 'Cruz',
        mobile_number: '+639181234567'
      },
      {
        email: 'customer3@test.com',
        first_name: 'Ana',
        last_name: 'Reyes',
        mobile_number: '+639191234567'
      },
      {
        email: 'testcustomer@gmail.com',
        first_name: 'Pedro',
        last_name: 'Garcia',
        mobile_number: '+639201234567'
      }
    ]
    
    sample_customers.each do |customer_data|
      customer = merchant.customers.create!(
        email: customer_data[:email],
        first_name: customer_data[:first_name],
        last_name: customer_data[:last_name],
        mobile_number: customer_data[:mobile_number]
      )
      puts "  Created sample customer: #{customer.full_name} (#{customer.email})"
    end
  end
end

# Create test customer accounts (with authentication/login capability)
test_customers = [
  {
    name: 'Maria Santos',
    email: 'customer@test.com',
    password: 'customer123',
    role: 'CUSTOMER',
    active: true
  },
  {
    name: 'Juan dela Cruz',
    email: 'customer2@test.com',
    password: 'customer123',
    role: 'CUSTOMER',
    active: true
  }
]

test_customers.each do |customer_data|
  customer = Merchant.find_or_create_by!(email: customer_data[:email]) do |c|
    c.name = customer_data[:name]
    c.password = customer_data[:password]
    c.role = customer_data[:role]
    c.active = customer_data[:active]
  end
  puts "Ensured test customer account: #{customer.name} (#{customer.email})"
end

# Create sample orders for test customers
test_merchant = Merchant.find_by(email: 'merchant@test.com')
if test_merchant && test_merchant.products.any?
  # Find or create customer record with email customer@test.com
  test_customer_record = test_merchant.customers.find_or_create_by!(email: 'customer@test.com') do |c|
    c.first_name = 'Maria'
    c.last_name = 'Santos'
    c.mobile_number = '+639171112222'
  end
  
  # Create a sample order if none exists
  if Order.where(customer: test_customer_record).empty?
    product = test_merchant.products.first
    
    order = Order.create!(
      merchant: test_merchant,
      customer: test_customer_record,
      order_type: 'ONLINE',
      status: 'PENDING',
      payment_status: 'PAYMENT_PENDING',
      payment_method: 'GCASH',
      shipping_method: 'STANDARD',
      reference_number: "ORD-#{Time.now.to_i}",
      subtotal: product.price,
      shipping_fee: 50.0,
      convenience_fee: 10.0,
      grand_total: product.price + 50.0 + 10.0
    )
    
    OrderItem.create!(
      order: order,
      product: product,
      quantity: 1,
      price_at_purchase: product.price
    )
    
    puts "  Created sample order for customer@test.com: #{order.reference_number}"
  end
end

puts "\n=== TEST ACCOUNTS CREATED ==="
puts "MERCHANT ACCOUNTS:"
Merchant.where(role: ['MERCHANT', 'ADMIN']).each do |merchant|
  puts "  #{merchant.name}: #{merchant.email} (Role: #{merchant.role})"
  puts "    Products: #{merchant.products.count}"
  puts "    Customers: #{merchant.customers.count}"
end

puts "\nCUSTOMER ACCOUNTS (with login):"
Merchant.where(role: 'CUSTOMER').each do |customer|
  puts "  #{customer.name}: #{customer.email}"
end

puts "\nCUSTOMER ACCOUNTS (for testing orders):"
Customer.limit(5).each do |customer|
  puts "  #{customer.full_name}: #{customer.email} - #{customer.mobile_number}"
end

puts "\n=== ACCESS INFORMATION ==="
puts "Frontend URL: http://localhost:5173"
puts "Backend GraphQL: http://127.0.0.1:3000/graphql"
puts "\nTest Merchant Login:"
puts "  Email: merchant@test.com"
puts "  Password: password123"
puts "\nAdmin Account:"
puts "  Email: admin@posystem.com" 
puts "  Password: admin123"
puts "\nCustomer Account (with login):"
puts "  Email: customer@test.com"
puts "  Password: customer123"
