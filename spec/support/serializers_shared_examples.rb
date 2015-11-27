shared_examples 'a json serializer' do
  let(:serializer) { described_class.new resource }
  subject { JSON.parse(serializer.to_json) }

  it 'should serialize to json' do
    expect{subject}.to_not raise_error
  end
end
