class User < ApplicationRecord
    extend Submit64::MetadataProvider

    has_many :articles
    has_many :comments

end
