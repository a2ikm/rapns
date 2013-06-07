module Rapns
  module C2dm
    class RegistrationIdsCountValidator < ActiveModel::Validator
      LIMIT = 1

      def validate(record)
        if record.registration_ids && record.registration_ids.size > LIMIT
          record.errors[:base] << "C2DM notification number of registration_ids cannot be larger than #{LIMIT}."
        end
      end
    end
  end
end
