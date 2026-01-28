class Article < ApplicationRecord
    extend Submit64::MetadataProvider

    has_many :comments
    belongs_to :user

    def self.submit64_form_builder
    {
      sections: [
        fields: [:a_string, :a_text, :a_number, :a_float, :user]
      ]
    }
    end

end
