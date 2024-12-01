Rails.application.routes.draw do
  # Mounting Devise Token Auth with custom controllers for registrations, sessions, and passwords
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations',
    sessions: 'auth/sessions',
    passwords: 'auth/passwords'
  }
  
  devise_scope :user do
    get '/auth/user', to: 'auth/sessions#show'  # To return the authenticated user's details
    post 'auth/employee_login', to: 'auth/sessions#create'  # For OTP login
    
    # OTP related routes
    post '/auth/resend_otp', to: 'auth/sessions#resend_otp'  # To resend OTP
    post '/auth/verify_otp', to: 'auth/sessions#verify_otp'  # To verify OTP
    
    # Password reset routes
    post '/auth/password', to: 'auth/passwords#create'  # To create password reset request (email with reset token)
    put '/auth/password', to: 'auth/passwords#update'    # To update the password with reset token
    
    # Account management routes
    delete '/auth/sign_out', to: 'auth/sessions#destroy', as: :logout  # To log out the user
    delete '/auth/delete_account', to: 'auth/registrations#destroy', as: :delete_account  # To delete the account
  end
  
  # Custom routes for user email confirmation
  get 'users/email_confirmed', to: 'application#email_confirmed'
  get 'users/confirm_email', to: 'application#confirm_email', as: 'confirm_email'

  # Admin namespace routes
  namespace :admin do
    get 'transactions/download'
    get 'commissions/create'
    
    # Agents CRUD routes
    resources :agents, only: [:index, :create] do
      # Nested transaction creation route under agents
      post 'transactions', to: 'agents#add_transaction', as: 'add_transaction'
    end

    resources :agents do
      resources :commissions, only: [:index, :create, :download]  # Added :index to the available actions
    end
    # User management routes
    resources :users, only: [:index, :create, :destroy]
  end

  # Employees namespace routes
  namespace :employees do
    # Agents CRUD routes
    resources :agents, only: [:create] do
      member do
        post 'create_transaction', to: 'agents#create_transaction'
      end
    end

    # Debt-related routes
    resources :debtors, only: [:create]  # Allows adding new debtors
    post 'debtors/:debtor_id/pay_debt', to: 'debtors#pay_debt'  # Route to mark debt as paid
    
    # Commissions routes
    resources :commissions, only: [:create]  # Allows adding commissions
  end

  # Wrapping the OTP related routes inside devise_scope :user
  devise_scope :user do
    post '/auth/resend_otp', to: 'auth/sessions#resend_otp'  # Route to resend OTP
    post '/auth/verify_otp', to: 'auth/sessions#verify_otp'  # Route to verify OTP
  end
end
