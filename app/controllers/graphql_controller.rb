# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  def execute
    # Handle Apollo Upload Server file uploads
    if request.post? && request.content_type&.include?("multipart/form-data")
      result = ApolloUploadServer::Middleware.new(lambda { |env|
        variables = prepare_variables(env["graphql.variables"])
        query = env["graphql.query"]
        operation_name = env["graphql.operation_name"]
        context = build_context

        PosBackendSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
      }).call(env)
      render json: result
    else
      variables = prepare_variables(params[:variables])
      query = params[:query]
      operation_name = params[:operationName]
      context = build_context

      result = PosBackendSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
      
      # Debug logging for orders query (removed - was causing errors)
      
      render json: result
    end
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end

  def build_context
    {
      current_merchant: current_merchant,
      current_user: current_merchant, # Alias for compatibility
    }
  end

  def current_merchant
    return nil unless authorization_header.present?

    token = authorization_header.split(' ').last
    decoded_token = decode_token(token)
    return nil unless decoded_token

    Merchant.find_by(id: decoded_token['merchant_id'])
  end

  def authorization_header
    request.headers['Authorization']
  end

  def decode_token(token)
    begin
      JwtTokenService.decode(token)
    rescue StandardError
      nil
    end
  end
end
