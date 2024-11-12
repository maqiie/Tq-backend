class Auth::ConfirmationsController < Devise::ConfirmationsController
    def show
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
  
      if resource.errors.empty?
        set_flash_message!(:notice, :confirmed)
        respond_with_navigational(resource) { redirect_to confirmation_success_path }
      else
        respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :new }
      end
    end
  
    private
  
    def confirmation_success_path
      # Define the path where users should be redirected after successful confirmation
      root_path
    end
  end
  