class EcwidApi::Client
  def profile
    self.get('profile').body
  end
end