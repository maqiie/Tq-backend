# Rails.application.routes.draw do
#   # Mounting Devise Token Auth with custom controllers for registrations, sessions, and passwords
#   mount_devise_token_auth_for 'User', at: 'auth', controllers: {
#     registrations: 'auth/registrations',
#     sessions: 'auth/sessions',
#     passwords: 'auth/passwords'
#   }
  
#   devise_scope :user do
#     get '/auth/user', to: 'auth/sessions#show'  # To return the authenticated user's details
#     post 'auth/employee_login', to: 'auth/sessions#create'  # For OTP login
    
#     # OTP related routes
#     post '/auth/resend_otp', to: 'auth/sessions#resend_otp'  # To resend OTP
#     post '/auth/verify_otp', to: 'auth/sessions#verify_otp'  # To verify OTP
    
#     # Password reset routes
#     post '/auth/password', to: 'auth/passwords#create'  # To create password reset request (email with reset token)
#     put '/auth/password', to: 'auth/passwords#update'    # To update the password with reset token
    
#     # Account management routes
#     delete '/auth/sign_out', to: 'auth/sessions#destroy', as: :logout  # To log out the user
#     delete '/auth/delete_account', to: 'auth/registrations#destroy', as: :delete_account  # To delete the account
#   end
  
#   # Custom routes for user email confirmation
#   get 'users/email_confirmed', to: 'application#email_confirmed'
#   get 'users/confirm_email', to: 'application#confirm_email', as: 'confirm_email'

#   # Admin namespace routes
#   namespace :admin do
#     get 'transactions/download'
#     get 'commissions/create'
    
#     # Agents CRUD routes
#     resources :agents, only: [:index, :create] do
#       # Nested transaction creation route under agents
#       post 'transactions', to: 'agents#add_transaction', as: 'add_transaction'
#     end

#     get 'dashboard', to: 'dashboard#index'
    
#     resources :agents do
#       resources :commissions, only: [:index, :create, :download]  # Added :index to the available actions
#     end

#     # User management routes
#     resources :users, only: [:index, :create, :destroy]
#   end

#   # Add this route for creating an employee
#   namespace :admin do
#     post '/users/create_employee', to: 'users#create', as: 'create_employee'
#   end

#   # Employees namespace routes
#   namespace :employees do
#     # Agents CRUD routes
#     resources :agents, only: [:index, :create] do
#       member do
#         post 'create_transaction', to: 'agents#create_transaction'
#       end
#     end

#     # Debt-related routes
#     resources :debtors, only: [:create]  # Allows adding new debtors
#     post 'debtors/:debtor_id/pay_debt', to: 'debtors#pay_debt'  # Route to mark debt as paid

#     # Commissions routes
#     resources :commissions, only: [:create]  # Allows adding commissions
#   end
  
#   namespace :employees do
#     get 'debtors/overview', to: 'debtors#overview'
#   end
  
#  namespace :employees do
#   resources :transactions do
#     get 'latest', on: :collection
#   end
# end


# resources :employees, only: [] do
#   resources :transactions, only: [:index, :create], module: 'employees'
# end

#  # Dashboard routes emploee
#    namespace :employees do
#     get 'dashboard', to: 'dashboard#index'

#     namespace :dashboard do
#       get 'stats/weekly', to: 'stats#weekly'
#       get 'stats/monthly', to: 'stats#monthly'
#       get 'stats/agents_performance', to: 'stats#agents_performance'
#     end
#   end

#   namespace :employees do
#   resources :commissions, only: [:index, :show, :create, :update, :destroy]
# end


# end


Rails.application.routes.draw do
  # Devise Token Auth for User
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations',
    sessions: 'auth/sessions',
    passwords: 'auth/passwords'
  }

  # Custom Devise routes
  devise_scope :user do
    get '/auth/user', to: 'auth/sessions#show'
    post '/auth/employee_login', to: 'auth/sessions#create'
    post '/auth/resend_otp', to: 'auth/sessions#resend_otp'
    post '/auth/verify_otp', to: 'auth/sessions#verify_otp'
    post '/auth/password', to: 'auth/passwords#create'
    put '/auth/password', to: 'auth/passwords#update'
    delete '/auth/sign_out', to: 'auth/sessions#destroy', as: :logout
    delete '/auth/delete_account', to: 'auth/registrations#destroy', as: :delete_account
  end

  # Email confirmation
  get 'users/email_confirmed', to: 'application#email_confirmed'
  get 'users/confirm_email', to: 'application#confirm_email', as: :confirm_email

  # ================================
  # Admin Routes
  # ================================
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'

    # Agent management
    resources :agents, only: [:index, :create] do
      post 'transactions', to: 'agents#add_transaction', as: 'add_transaction'
    end

    resources :agents do
      resources :commissions, only: [:index, :create]  # Nested commissions
    end

    get 'transactions/download', to: 'transactions#download'
    get 'commissions/create', to: 'commissions#create'

    # Users
    resources :users, only: [:index, :create, :destroy]
    post '/users/create_employee', to: 'users#create', as: 'create_employee'
  end

  # ================================
  # Employee Routes
  # ================================
  namespace :employees do
    # Dashboard
    get 'dashboard', to: 'dashboard#index'
    namespace :dashboard do
      get 'stats/weekly', to: 'stats#weekly'
      get 'stats/monthly', to: 'stats#monthly'
      get 'stats/agents_performance', to: 'stats#agents_performance'
    end

    # Agents
    resources :agents, only: [:index, :create] do
      post 'create_transaction', on: :member
    end

    # Debtors
    resources :debtors, only: [:create]
    post 'debtors/:debtor_id/pay_debt', to: 'debtors#pay_debt'
    get 'debtors/overview', to: 'debtors#overview'

    # Commissions
    resources :commissions, only: [:index, :show, :create, :update, :destroy]

    # Transactions
    resources :transactions do
      get 'latest', on: :collection
    end
  end

  # Allow nested employee transactions: /employees/:employee_id/transactions
  resources :employees, only: [] do
    resources :transactions, only: [:index, :create], module: 'employees'
  end
end
