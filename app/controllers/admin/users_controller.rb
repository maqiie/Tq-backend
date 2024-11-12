module Admin
  class UsersController < ApplicationController
    before_action :authenticate_admin!  # Ensure the user is an admin

    # GET /admin/users
    def index
      @employees = User.where(role: 'employee')  # Fetch only employees
      render json: @employees
    end

    # POST /admin/users
    def create
      @user = User.new(user_params)
      @user.otp_required_for_login = false  # Disable OTP for employees
      @user.role = 'employee'  # Ensure the user is created as an employee

      # Automatically set the email extension based on the company name "TQCashpoint"
      if @user.name.present?
        company_email_extension = 'tqcashpoint.com'
        @user.email = generate_email(@user.name, company_email_extension)
      end

      if @user.save
        # Send a success response with the created user details
        render json: { message: 'Employee created successfully', user: @user }, status: :created
      else
        # Send an error response with the validation errors
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /admin/users/:id
    def destroy
      @user = User.find_by(id: params[:id])

      if @user && @user.role == 'employee'
        if @user.destroy
          render json: { message: 'Employee deleted successfully' }, status: :ok
        else
          render json: { errors: 'Failed to delete employee' }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Employee not found or cannot be deleted' }, status: :not_found
      end
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def generate_email(name, company_extension)
      # Generate email based on name and company extension
      "#{name.downcase.gsub(' ', '')}@#{company_extension}"
    end

    # Ensure only admins can access this action
    def authenticate_admin!
      render json: { error: 'You must be an admin to perform this action.' }, status: :forbidden unless current_user&.admin?
    end
  end
end
