---
title: Types supplémentaires
---

# Types supplémentaires

Des types supplémentaires sont à disposition pour des cas particuliés :  

- Champ de couleur `:color`
- Champ WYSIWYG `:wysiwyg`


```ruby
class MonModele < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def self.submit64_form_builder
    {
      sections: [
        fields: [
          {
            target: :content, :extra_type: :wysiwyg
          }
        ]
      ]
    }
  end

end
```
<br /><br /> 
