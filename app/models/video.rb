class Video < ApplicationRecord
    has_one_attached :main_image
    attr_accessor :type


end
