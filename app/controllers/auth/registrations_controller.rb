
# class Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
#   include Devise::Controllers::Helpers
#   include Devise::Controllers::UrlHelpers
  
#   # Override the create method to handle email confirmation and 2FA setup after registration
#   def create
#     super do |resource|
#       # Check if the resource was successfully created
#       if resource.persisted?
#         # Set the @token instance variable to the confirmation_token
#         @token = resource.confirmation_token
#         # Send confirmation email if confirmation is required
#         if resource.confirmed?
#           resource.send_confirmation_instructions
#         end
        
#         # Initiate the 2FA setup process if it's required for login
#         resource.send_new_otp if resource.otp_required_for_login
#       end
#     end
#   end

#   private

#   def sign_up_params
#     params.require(:user).permit(:name, :email, :password, :password_confirmation, :nickname, :confirmed_at, :confirmation_token)
#   end

#   def configure_sign_up_params
#     devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation, :nickname, :confirmed_at, :confirmation_token])
#   end
# end


class Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  include Devise::Controllers::Helpers
  include Devise::Controllers::UrlHelpers

  # Override the create method to handle email confirmation and 2FA setup after registration
  def create
    super do |resource|
      if resource.persisted?
        # Set the role to admin using the enum
        resource.role = :admin  # Use the symbol for 'admin'
        resource.save
  
        # Check if the email is confirmed after registration
        unless resource.confirmed?
          resource.send_confirmation_instructions
        end
  
        # Initiate the 2FA setup process if it's required for login
        if resource.otp_required_for_login
          resource.send_new_otp
        end
      end
    end
  end

  private

  # Customize the permitted parameters during user sign up
  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :nickname)
  end

  # Configure the allowed parameters for Devise's sign-up flow
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation, :nickname])
  end
end
