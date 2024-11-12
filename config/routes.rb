
Rails.application.routes.draw do
  # Mounting Devise Token Auth with custom controllers for registrations, sessions, and passwords
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations',
    sessions: 'auth/sessions',
    passwords: 'auth/passwords'
  }
  devise_scope :user do
    get '/auth/user', to: 'auth/sessions#show'  # This will return the authenticated user's details
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
    resources :users, only: [:new, :create]
  end


end
