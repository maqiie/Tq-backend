

# class ApplicationController < ActionController::Base
#   before_action :configure_permitted_parameters, if: :devise_controller?
#   skip_before_action :verify_authenticity_token
#   after_action :set_cors_headers


#   include DeviseTokenAuth::Concerns::SetUserByToken

#   rescue_from CanCan::AccessDenied do |exception|
#     redirect_to root_path, alert: "Access denied."
#   end
  
#   def confirm_email
#     confirmation_token = params[:confirmation_token]
#     user = User.find_by(confirmation_token: confirmation_token)

#     if user
#       user.confirm # Assuming Devise's `confirm` method, which you might need to adjust
#       redirect_to root_path, notice: "Email confirmed successfully!"
#     else
#       redirect_to root_path, alert: "Invalid confirmation token."
#     end
#   end

#   def email_confirmed
#     render plain: "Email confirmed successfully!"
#   end
#   protected

#   # def configure_permitted_parameters
#   #   devise_parameter_sanitizer.permit(:sign_in, keys: [:redirect_url, :otp_attempt])
#   # end
#   def configure_permitted_parameters
#     devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
#     devise_parameter_sanitizer.permit(:password, keys: [:reset_password_token, :password, :password_confirmation])
#     devise_parameter_sanitizer.permit(:password, keys: [:redirect_url]) # For password reset
#   end
  
#   after_action :set_cors_headers


#   def set_cors_headers
#     response.headers['Access-Control-Expose-Headers'] = 'Authorization'
#   end
  

# end

# class ApplicationController < ActionController::Base
#   skip_before_action :verify_authenticity_token
#   include DeviseTokenAuth::Concerns::SetUserByToken

#   # Define CORS headers after every action
#   after_action :set_cors_headers

#   # Handle access denied errors
#   rescue_from CanCan::AccessDenied do |exception|
#     redirect_to root_path, alert: "Access denied."
#   end
  
#   # Authenticate that the current user is an admin
#   def authenticate_admin!
#     unless current_user && current_user.role == "admin"
#       render json: { error: "Unauthorized" }, status: :forbidden
#     end
#   end
  
  
#   # Email confirmation methods
#   def confirm_email
#     confirmation_token = params[:confirmation_token]
#     user = User.find_by(confirmation_token: confirmation_token)

#     if user
#       user.confirm # Confirm the user (assumes Devise's confirm method)
#       redirect_to root_path, notice: "Email confirmed successfully!"
#     else
#       redirect_to root_path, alert: "Invalid confirmation token."
#     end
#   end

#   def email_confirmed
#     render plain: "Email confirmed successfully!"
#   end

#   # Authenticate that the current user is an employee
#   def authenticate_employee!
#     unless current_user&.employee?
#       render json: { error: 'You need to sign in as an employee before continuing.' }, status: :unauthorized
#     end
#   end
  
#   def current_employee
#     # Return the user if their role is employee
#     current_user if current_user&.employee?
#   end
  
#   protected

#   # Configure permitted parameters for Devise
#   def configure_permitted_parameters
#     # Parameters for sign-in
#     devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password, :redirect_url])

#     # Parameters for password reset
#     devise_parameter_sanitizer.permit(:reset_password, keys: [:reset_password_token, :password, :password_confirmation, :redirect_url])

#     # Parameters for account update (like updating password after sign-in)
#     devise_parameter_sanitizer.permit(:account_update, keys: [:password, :password_confirmation, :current_password])
#   end

#   # Set CORS headers for API responses
#   def set_cors_headers
#     response.headers['Access-Control-Expose-Headers'] = 'Authorization'
#   end

#   # Call the method to configure Devise permitted parameters when it's a Devise controller
#   before_action :configure_permitted_parameters, if: :devise_controller?
# end
class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token
  include DeviseTokenAuth::Concerns::SetUserByToken

  # Handle access denied errors
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: "Access denied."
  end

  # Authenticate that the current user is an admin
  def authenticate_admin!
    unless current_user && current_user.role == "admin"
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end

  # Email confirmation methods
  def confirm_email
    confirmation_token = params[:confirmation_token]
    user = User.find_by(confirmation_token: confirmation_token)

    if user
      user.confirm # Confirm the user (assumes Devise's confirm method)
      redirect_to root_path, notice: "Email confirmed successfully!"
    else
      redirect_to root_path, alert: "Invalid confirmation token."
    end
  end

  def email_confirmed
    render plain: "Email confirmed successfully!"
  end

  # Authenticate that the current user is an employee
  def authenticate_employee!
    unless current_user&.employee?
      render json: { error: 'You need to sign in as an employee before continuing.' }, status: :unauthorized
    end
  end

  def current_employee
    # Return the user if their role is employee
    current_user if current_user&.employee?
  end

  protected

  # Configure permitted parameters for Devise
  def configure_permitted_parameters
    # Parameters for sign-in
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password, :redirect_url])

    # Parameters for password reset
    devise_parameter_sanitizer.permit(:reset_password, keys: [:reset_password_token, :password, :password_confirmation, :redirect_url])

    # Parameters for account update (like updating password after sign-in)
    devise_parameter_sanitizer.permit(:account_update, keys: [:password, :password_confirmation, :current_password])
  end

  # Define CORS headers after every action - safely add Authorization to exposed headers
  after_action :set_cors_headers

  def set_cors_headers
    existing = response.headers['Access-Control-Expose-Headers']
    # Headers your frontend needs to access for DeviseTokenAuth
    needed_headers = ['access-token', 'expiry', 'token-type', 'uid', 'client', 'Authorization']

    if existing.present?
      existing_headers = existing.split(',').map(&:strip)
      merged_headers = (existing_headers + needed_headers).uniq
      response.headers['Access-Control-Expose-Headers'] = merged_headers.join(', ')
    else
      response.headers['Access-Control-Expose-Headers'] = needed_headers.join(', ')
    end
  end

  # Call configure permitted parameters only on Devise controllers
  before_action :configure_permitted_parameters, if: :devise_controller?
end
