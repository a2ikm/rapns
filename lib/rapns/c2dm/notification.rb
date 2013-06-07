module Rapns
  module C2dm
    class Notification < Rapns::Notification
      validates :registration_ids, :presence => true
      validates_with Rapns::C2dm::PostDataSizeValidator
      validates_with Rapns::C2dm::RegistrationIdsCountValidator

      def registration_ids=(ids)
        ids = [ids] if ids && !ids.is_a?(Array)
        super
      end

      def as_json
        json = {
          'registration_id' => registration_ids[0],
          'delay_while_idle' => delay_while_idle,
          'data.content' => data
        }

        if collapse_key
          json['collapse_key'] = collapse_key
        end

        json
      end

      def to_post_data
        URI.encode_www_form(as_json)  
      end

      def post_data_size
        to_post_data.bytesize
      end
    end
  end
end
