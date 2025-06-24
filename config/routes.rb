
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
  
    # Agent management with transaction route
    resources :agents, only: [:index, :create] do
      post 'transactions', to: 'agents#add_transaction', as: 'add_transaction'
  
      resources :commissions, only: [:index, :create] do
        collection do
          get :download  # /admin/agents/:agent_id/commissions/download
        end
      end
    end
  
    # Global commissions (not nested under agent)
    resources :commissions, only: [:index]
  
    get 'transactions/download', to: 'transactions#download'
    resources :debtors, only: [:index]
  
    # Users
    resources :users, only: [:index, :create, :destroy]
    post '/users/create_employee', to: 'users#create', as: 'create_employee'
  end
  
# Outside of namespace :admin
get '/transactions', to: 'transactions#index'
# For both roles to access

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
