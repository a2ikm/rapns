module Rapns
  module Daemon
    module C2dm
      # https://developers.google.com/android/c2dm/
      class Delivery < Rapns::Daemon::Delivery
        include Rapns::MultiJsonHelper

        C2DM_URI = URI.parse('https://android.apis.google.com/c2dm/send')
        UNAVAILABLE_STATES = ['Unavailable', 'InternalServerError']

        def initialize(app, http, notification)
          @app = app
          @http = http
          @notification = notification
        end

        def perform
          begin
            handle_response(do_post)
          rescue Rapns::DeliveryError => error
            mark_failed(error.code, error.description)
            raise
          end
        end

        protected

        def handle_response(response)
          case response.code.to_i
          when 200
            ok(response)
          when 400
            bad_request(response)
          when 401
            unauthorized(response)
          when 500
            internal_server_error(response)
          when 503
            service_unavailable(response)
          else
            raise Rapns::DeliveryError.new(response.code, @notification.id, HTTP_STATUS_CODES[response.code.to_i])
          end
        end

        def ok(response)
          body = parse_response_body(response.body)
          if params['Error']
            handle_errors(response, body)
          else
            mark_delivered
            Rapns.logger.info("[#{@app.name}] #{@notification.id} sent to #{@notification.registration_ids.join(', ')}")
          end
        end

        def handle_errors(response, body)
          error = body['Error']
          raise Rapns::DeliveryError.new(nil, @notification.id, describe_error(error))
        end

        def bad_request(response)
          raise Rapns::DeliveryError.new(400, @notification.id, 'GCM failed to parse the JSON request. Possibly an rapns bug, please open an issue.')
        end

        def unauthorized(response)
          raise Rapns::DeliveryError.new(401, @notification.id, 'Unauthorized, check your App auth_key.')
        end

        def internal_server_error(response)
          retry_delivery(@notification, response)
          Rapns.logger.warn("C2DM responded with an Internal Error. " + retry_message)
        end

        def service_unavailable(response)
          retry_delivery(@notification, response)
          Rapns.logger.warn("C2DM responded with an Service Unavailable Error. " + retry_message)
        end

        def deliver_after_header(response)
          if response.header['retry-after']
            retry_after = if response.header['retry-after'].to_s =~ /^[0-9]+$/
              Time.now + response.header['retry-after'].to_i
            else
              Time.httpdate(response.header['retry-after'])
            end
          end
        end

        def retry_delivery(notification, response)
          if time = deliver_after_header(response)
            retry_after(notification, time)
          else
            retry_exponentially(notification)
          end
        end

        def describe_error(error)
          "Failed to deliver to recipient #{@notification.id}. Errors: #{error}."
        end

        def retry_message
          "Notification #{@notification.id} will be retired after #{@notification.deliver_after.strftime("%Y-%m-%d %H:%M:%S")} (retry #{@notification.retries})."
        end

        def do_post
          post = Net::HTTP::Post.new(C2DM_URI.path, initheader = {'Content-Type'  => 'application/x-www-form-urlencoded',
                                                                 'Content-Length' => @notification.post_data_size,
                                                                 'Authorization' => "GoogleLogin auth=#{@notification.app.auth_key}"})
          post.body = @notification.to_post_data
          @http.request(C2DM_URI, post)
        end

        def parse_response_body(body)
          body.split("\n").inject({}) do |s, r|
            k, v = r.split("=")
            s[k] = v
            s
          end
        end

        HTTP_STATUS_CODES = {
          100  => 'Continue',
          101  => 'Switching Protocols',
          102  => 'Processing',
          200  => 'OK',
          201  => 'Created',
          202  => 'Accepted',
          203  => 'Non-Authoritative Information',
          204  => 'No Content',
          205  => 'Reset Content',
          206  => 'Partial Content',
          207  => 'Multi-Status',
          226  => 'IM Used',
          300  => 'Multiple Choices',
          301  => 'Moved Permanently',
          302  => 'Found',
          303  => 'See Other',
          304  => 'Not Modified',
          305  => 'Use Proxy',
          306  => 'Reserved',
          307  => 'Temporary Redirect',
          400  => 'Bad Request',
          401  => 'Unauthorized',
          402  => 'Payment Required',
          403  => 'Forbidden',
          404  => 'Not Found',
          405  => 'Method Not Allowed',
          406  => 'Not Acceptable',
          407  => 'Proxy Authentication Required',
          408  => 'Request Timeout',
          409  => 'Conflict',
          410  => 'Gone',
          411  => 'Length Required',
          412  => 'Precondition Failed',
          413  => 'Request Entity Too Large',
          414  => 'Request-URI Too Long',
          415  => 'Unsupported Media Type',
          416  => 'Requested Range Not Satisfiable',
          417  => 'Expectation Failed',
          418  => "I'm a Teapot",
          422  => 'Unprocessable Entity',
          423  => 'Locked',
          424  => 'Failed Dependency',
          426  => 'Upgrade Required',
          500  => 'Internal Server Error',
          501  => 'Not Implemented',
          502  => 'Bad Gateway',
          503  => 'Service Unavailable',
          504  => 'Gateway Timeout',
          505  => 'HTTP Version Not Supported',
          506  => 'Variant Also Negotiates',
          507  => 'Insufficient Storage',
          510  => 'Not Extended',
        }
      end
    end
  end
end