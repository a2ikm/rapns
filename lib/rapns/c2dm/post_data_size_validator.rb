module Rapns
  module C2dm
    class PostDataSizeValidator < ActiveModel::Validator
      LIMIT = 1024

      def validate(record)
        if record.post_data_size > LIMIT
          record.errors[:base] << "C2DM notification post data cannot be larger than #{LIMIT} bytes."
        end
      end
    end
  end
end
