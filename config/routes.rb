
Rails.application.routes.draw do
  namespace :employees do
    get 'debtors/create'
    get 'debtors/pay_debt'
    get 'agents/create_transaction'
    get 'commissions/create'
  end
  # Mounting Devise Token Auth with custom controllers for registrations, sessions, and passwords
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations',
    sessions: 'auth/sessions',
    passwords: 'auth/passwords'
  }
  devise_scope :user do
    get '/auth/user', to: 'auth/sessions#show'  # This will return the authenticated user's details
  end

  devise_scope :user do
    post 'auth/employee_login', to: 'auth/sessions#create'
  end
  
  # Wrapping the OTP related routes inside devise_scope :user
  devise_scope :user do
    post '/auth/resend_otp', to: 'auth/sessions#resend_otp'  # Route to resend OTP
    post '/auth/verify_otp', to: 'auth/sessions#verify_otp'  # Route to verify OTP
    post '/auth/password', to: 'auth/passwords#create'       # For creating a password reset request (email with reset token)
    put '/auth/password', to: 'auth/passwords#update'        # For updating the password with reset token
  end

  # Custom routes for other functionalities
  get 'users/email_confirmed', to: 'application#email_confirmed'
  get 'users/confirm_email', to: 'application#confirm_email', as: 'confirm_email'

  # Wrapping logout and delete account routes inside devise_scope :user
  devise_scope :user do
    delete '/auth/sign_out', to: 'auth/sessions#destroy', as: :logout  # Route to log out the user
    delete '/auth/delete_account', to: 'auth/registrations#destroy', as: :delete_account  # Route to delete the account
  end



  namespace :admin do
    get 'transactions/download'
    get 'commissions/create'
    get 'agents/index'
    get 'agents/create'
    get 'agents/add_transaction'
    resources :users, only: [:index, :create, :destroy]
  end
  
  namespace :admin do
    resources :agents, only: [:index, :create] do
      post 'transactions', to: 'agents#add_transaction'
    end
  end
  namespace :employees do
    resources :agents, only: [] do
      post 'create_transaction', on: :member  # Allow creating transactions for agents
    end
    resources :debtors, only: [:create]  # Allow adding new debtors
    post 'debtors/:debtor_id/pay_debt', to: 'debtors#pay_debt'  # Mark debt as paid
  
    resources :commissions, only: [:create]  # Allow adding commissions
  end
  


end
