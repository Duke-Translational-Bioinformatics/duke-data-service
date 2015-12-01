shared_examples 'a json serializer' do
  let(:serializer) { described_class.new resource }
  subject { JSON.parse(serializer.to_json) }

  it 'should serialize to json' do
    expect{subject}.to_not raise_error
  end
end

shared_examples 'a has_one association with' do |association_root, serialized_with|
  it "#{association_root} serialized using #{serialized_with}" do
    expect(described_class._associations).to have_key(association_root)
    expect(described_class._associations[association_root]).to be_a(ActiveModel::Serializer::Association::HasOne)
    expect(described_class._associations[association_root].serializer_from_options).to eq(serialized_with)
  end
end

shared_examples 'a has_many association with' do |association_root, serialized_with|
  it "#{association_root} serialized using #{serialized_with}" do
    expect(described_class._associations).to have_key(association_root)
    expect(described_class._associations[association_root]).to be_a(ActiveModel::Serializer::Association::HasMany)
    expect(described_class._associations[association_root].serializer_from_options).to eq(serialized_with)
  end
end
