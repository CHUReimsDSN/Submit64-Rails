class Comment < ApplicationRecord
    extend Submit64::MetadataProvider

    belongs_to :user
    belongs_to :article

end
