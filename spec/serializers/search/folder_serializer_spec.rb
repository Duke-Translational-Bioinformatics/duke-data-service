require 'rails_helper'

RSpec.describe Search::FolderSerializer, type: :serializer do

  let(:folder) { FactoryGirl.create(:folder) }
  it_behaves_like 'a serialized Folder', :folder do
    it_behaves_like 'a json serializer'

    context 'with meta_templates' do
      let(:meta_template) { FactoryGirl.create(:meta_template, templatable: data_file) }
      let(:property) { FactoryGirl.create(:property, template: meta_template.template) }
      let(:meta_property){ FactoryGirl.create(:meta_property, meta_template: meta_template, property: property) }
      include_context 'elasticsearch prep', [:meta_template, :property, :meta_property], [:data_file]

      it_behaves_like 'a json serializer' do
        it_behaves_like 'a metadata annotated document'
      end
    end
  end
end
