# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_05_000323) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.bigint "merchant_id", null: false
    t.string "mobile_number"
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_customers_on_merchant_id"
  end

  create_table "delivery_addresses", force: :cascade do |t|
    t.string "barangay"
    t.string "building"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "floor"
    t.string "landmark"
    t.bigint "order_id", null: false
    t.string "province"
    t.string "remarks"
    t.string "room_unit"
    t.string "street"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_delivery_addresses_on_order_id"
  end

  create_table "merchants", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.string "role", default: "MERCHANT", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.decimal "price_at_purchase"
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.decimal "convenience_fee"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.decimal "grand_total"
    t.bigint "merchant_id", null: false
    t.string "order_type"
    t.string "payment_method"
    t.string "payment_status"
    t.string "reference_number"
    t.decimal "shipping_fee"
    t.string "shipping_method"
    t.string "status"
    t.decimal "subtotal"
    t.datetime "updated_at", null: false
    t.decimal "voucher_discount"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["merchant_id"], name: "index_orders_on_merchant_id"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled"
    t.bigint "merchant_id", null: false
    t.string "name"
    t.string "payment_type"
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_payment_methods_on_merchant_id"
  end

  create_table "payment_proofs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_key"
    t.string "image_content_type"
    t.binary "image_data"
    t.string "image_filename"
    t.integer "merchant_id"
    t.bigint "order_id", null: false
    t.text "remarks"
    t.string "status", default: "PENDING"
    t.datetime "updated_at", null: false
    t.datetime "verified_at", precision: nil
    t.index ["order_id"], name: "index_payment_proofs_on_order_id", unique: true
    t.index ["status"], name: "index_payment_proofs_on_status"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "image_content_type"
    t.binary "image_data"
    t.string "image_filename"
    t.string "image_url"
    t.bigint "merchant_id", null: false
    t.string "name"
    t.decimal "price"
    t.string "product_type"
    t.integer "stock_quantity", default: 0
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["merchant_id"], name: "index_products_on_merchant_id"
  end

  create_table "shipping_methods", force: :cascade do |t|
    t.decimal "base_fee"
    t.string "calculation_type"
    t.datetime "created_at", null: false
    t.boolean "enabled"
    t.bigint "merchant_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_shipping_methods_on_merchant_id"
  end

  create_table "vouchers", force: :cascade do |t|
    t.boolean "active"
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "current_uses"
    t.decimal "discount_amount"
    t.decimal "discount_percentage"
    t.datetime "expires_at"
    t.integer "max_uses"
    t.bigint "merchant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_vouchers_on_merchant_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "customers", "merchants"
  add_foreign_key "delivery_addresses", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "merchants"
  add_foreign_key "payment_methods", "merchants"
  add_foreign_key "payment_proofs", "orders"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "merchants"
  add_foreign_key "shipping_methods", "merchants"
  add_foreign_key "vouchers", "merchants"
end
