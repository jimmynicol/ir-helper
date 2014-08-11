require 'ir_helper/helper'

module IrHelper
  # Series of view helpers building url strings for image-resizer endpoints
  module IrHelper
    def self.included(base)
      base.class_eval do
        include ::IrHelper::Helper
      end
    end
  end
end
