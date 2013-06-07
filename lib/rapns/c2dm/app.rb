module Rapns
  module C2dm
    class App < Rapns::App
      validates :auth_key, :presence => true
    end
  end
end
