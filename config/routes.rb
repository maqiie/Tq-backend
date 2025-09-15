Rails.application.routes.draw do
  # ================================
  # Devise Token Auth for User
  # ================================
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations',
    sessions: 'auth/sessions',
    passwords: 'auth/passwords'
  }

  # Custom Devise routes
  devise_scope :user do
    get    '/auth/user',           to: 'auth/sessions#show'
    post   '/auth/employee_login', to: 'auth/sessions#create'
    post   '/auth/resend_otp',     to: 'auth/sessions#resend_otp'
    post   '/auth/verify_otp',     to: 'auth/sessions#verify_otp'
    post   '/auth/password',       to: 'auth/passwords#create'
    put    '/auth/password',       to: 'auth/passwords#update'
    delete '/auth/sign_out',       to: 'auth/sessions#destroy', as: :logout
    delete '/auth/delete_account', to: 'auth/registrations#destroy', as: :delete_account
  end

  # ================================
  # Email confirmation
  # ================================
  get 'users/email_confirmed', to: 'application#email_confirmed'
  get 'users/confirm_email',   to: 'application#confirm_email', as: :confirm_email

  # ================================
  # Admin Routes
  # ================================
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'

    resources :agents, only: [:index, :create] do
      post 'transactions', to: 'agents#add_transaction', as: 'add_transaction'

      resources :commissions, only: [:index, :create] do
        collection do
          get :download  # /admin/agents/:agent_id/commissions/download
        end
      end
    end

    resources :commissions, only: [:index] # Global commissions
    resources :transactions, only: [:index, :show, :create] do
      collection do
        get :download  # /admin/transactions/download
      end
    end

    resources :debtors, only: [:index]
    resources :users, only: [:index, :create, :destroy]
    post '/users/create_employee', to: 'users#create', as: 'create_employee'
  end

  # ================================
  # Public API Routes (if needed)
  # ================================
  get '/transactions',                  to: 'admin/transactions#index'
  get '/agents',                        to: 'admin/agents#index'
  get '/agents/:id',                    to: 'admin/agents#show'
  get '/agents/:id/transactions',       to: 'admin/agents#transactions'

  # ================================
  # Employee Routes
  # ================================
  namespace :employees do
    # Dashboard
    get 'dashboard', to: 'dashboard#index'

    namespace :dashboard do
      get 'stats',                 to: 'stats#index'
      get 'stats/weekly',         to: 'stats#weekly'
      get 'stats/monthly',        to: 'stats#monthly'
      get 'stats/agents_performance', to: 'stats#agents_performance'
    end

    # Agents
    resources :agents, only: [:index, :create] do
      post 'create_transaction', on: :member
      get  'transactions/latest', on: :member
      get  'transactions',        on: :member


    end

    # Debtors
    resources :debtors, only: [:create]
    post 'debtors/:debtor_id/pay_debt', to: 'debtors#pay_debt'
    get 'debtors/overview',             to: 'debtors#overview'

    # Commissions
    resources :commissions, only: [:index, :show, :create, :update, :destroy]

    # Transactions
    resources :transactions do
      get 'latest', on: :collection
    end
  end

  # Nested route for employee transactions by employee ID
  resources :employees, only: [] do
    resources :transactions, only: [:index, :create], module: 'employees'
  end
end
