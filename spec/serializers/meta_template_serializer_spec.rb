require 'rails_helper'

RSpec.describe MetaTemplateSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:meta_template) }

  it_behaves_like 'a has_one association with', :templatable, TemplatableSerializer, root: :object
  it_behaves_like 'a has_one association with', :template, TemplatePreviewSerializer
  it_behaves_like 'a has_many association with', :meta_properties, MetaPropertySerializer, root: :properties

  it_behaves_like 'a json serializer'
end
