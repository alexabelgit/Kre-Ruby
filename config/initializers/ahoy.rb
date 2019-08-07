Ahoy.api = true
Ahoy.server_side_visits = false

class Ahoy::Store < Ahoy::DatabaseStore
  def visit_model
    Visit
  end
end
