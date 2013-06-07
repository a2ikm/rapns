module Rapns
  module Daemon
    module C2dm
      class DeliveryHandler < Rapns::Daemon::DeliveryHandler
        def initialize(app)
          @app = app
          @http = Net::HTTP::Persistent.new('rapns')
        end

        def deliver(notification)
          Rapns::Daemon::C2dm::Delivery.perform(@app, @http, notification)
        end

        def stopped
          @http.shutdown
        end
      end
    end
  end
end
