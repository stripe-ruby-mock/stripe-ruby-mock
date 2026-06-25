module StripeMock
  module RequestHandlers
    module VerificationSessions
      def VerificationSessions.included(klass)
        klass.add_handler 'post /v1/identity/verification_sessions', :new_verification_session
        klass.add_handler 'get /v1/identity/verification_sessions', :list_verification_sessions
        klass.add_handler 'get /v1/identity/verification_sessions/([^/]*)', :get_verification_session
        klass.add_handler 'post /v1/identity/verification_sessions/([^/]*)/cancel', :cancel_verification_session
        klass.add_handler 'post /v1/identity/verification_sessions/([^/]*)/redact', :redact_verification_session
      end

      def new_verification_session(route, method_url, params, headers)
        id = params[:id] || new_id('vs')

        # Validate required parameters
        require_param(:type) if params[:type].nil? || params[:type].empty?

        # Validate type values
        valid_types = ['document', 'id_number']
        unless valid_types.include?(params[:type])
          raise Stripe::InvalidRequestError.new("Invalid type: must be one of #{valid_types.join(', ')}", :type, http_status: 400)
        end

        # Create verification session
        verification_sessions[id] = Data.mock_verification_session({
          id: id,
          type: params[:type],
          options: params[:options] || {},
          metadata: params[:metadata] || {},
          return_url: params[:return_url],
          cancel_url: params[:cancel_url]
        })
      end

      def list_verification_sessions(route, method_url, params, headers)
        Data.mock_list_object(verification_sessions.values, params)
      end

      def get_verification_session(route, method_url, params, headers)
        route =~ method_url
        verification_session = assert_existence :verification_session, $1, verification_sessions[$1]
        verification_session
      end

      def cancel_verification_session(route, method_url, params, headers)
        route =~ method_url
        verification_session = assert_existence :verification_session, $1, verification_sessions[$1]
        
        # Update status to canceled
        verification_session[:status] = "canceled"
        verification_session[:canceled_at] = Time.now.to_i
        
        verification_session
      end

      def redact_verification_session(route, method_url, params, headers)
        route =~ method_url
        verification_session = assert_existence :verification_session, $1, verification_sessions[$1]
        
        # Update redaction status
        verification_session[:redaction] = {
          status: "processing"
        }
        
        verification_session
      end
    end
  end
end 