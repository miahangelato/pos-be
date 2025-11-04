class PaymentProofsController < ActionController::Base
  protect_from_forgery with: :null_session
  
  def new
    @order = Order.find(params[:order_id])
    @payment_proof = PaymentProof.new
  end
  
  def create
    Rails.logger.info "PaymentProof params: #{params.inspect}"
    @order = Order.find(params[:order_id])
    Rails.logger.info "Order found: #{@order.reference_number}, payment_method: #{@order.payment_method}"
    
    # Validate order exists and is GCASH
    unless @order.gcash?
      return render json: { error: 'This order does not require payment proof' }, status: :unprocessable_entity
    end
    
    # Validate file is present
    unless params[:file].present?
      return render json: { error: 'Payment proof file is required' }, status: :unprocessable_entity
    end
    
    # Check if payment proof already exists
    if @order.payment_proof.present?
      return render json: { error: 'Payment proof already submitted for this order' }, status: :unprocessable_entity
    end
    
    # Create payment proof with Active Storage attachment
    @payment_proof = @order.build_payment_proof(
      status: :pending,
      remarks: params[:remarks]
    )
    
    # Attach the uploaded file using Active Storage
    @payment_proof.image.attach(params[:file]) if params[:file].present?
    
    if @payment_proof.save
      # Send merchant notification email
      OrderMailer.payment_proof_received(@order).deliver_later
      
      render json: { 
        message: 'Payment proof submitted successfully. Please wait for merchant verification.',
        order_id: @order.id,
        reference_number: @order.reference_number
      }, status: :created
    else
      Rails.logger.error "PaymentProof validation failed: #{@payment_proof.errors.full_messages}"
      render json: { 
        error: 'Validation failed', 
        errors: @payment_proof.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
end
