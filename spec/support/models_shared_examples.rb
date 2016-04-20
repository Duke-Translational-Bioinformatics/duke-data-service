shared_examples 'a kind' do
  let(:kind_name) { subject.class.name }
  let(:resource_serializer) { ActiveModel::Serializer.serializer_for(subject) }
  let(:expected_kind) { ['dds', kind_name.downcase].join('-') }
  let(:serialized_kind) { true }
  it 'should have a kind' do
    expect(subject).to respond_to('kind')
    expect(subject.kind).to eq(expected_kind)
  end

  it 'should serialize the kind' do
    if serialized_kind
      serializer = resource_serializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('kind')
      expect(parsed_json["kind"]).to eq(subject.kind)
    end
  end
end

shared_examples 'a graphed model' do |auto_create: false, logically_deleted: false|
  let(:kind_name) {subject.class.name}
  let(:graph_node_name) { "Graph::#{kind_name}" }

  it 'should support graph_node method' do
    is_expected.to respond_to 'graph_node'
  end

  if auto_create
    it 'should auto_create' do
      expect(subject).to be
      expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(1)
    end
  else
    it 'should not auto_create' do
      expect(subject).to be
      expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(0)
    end
  end

  context 'that does not exist in graphDB' do
    it 'should create a graphed model with model_id user.id and model_kind user.kind' do
      existing_node = subject.graph_node
      if existing_node
        existing_node.destroy
      end
      expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(0)
      graph_agent = subject.graph_node
      expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(1)
      expect(graph_agent).to be
      expect(graph_agent.model_id).to eq(subject.id)
      expect(graph_agent.model_kind).to eq(subject.kind)
    end
  end
  context 'that does exist in graphDB' do
    let(:graphed_node) { subject.graph_node }
    it 'should not create a graphed model with model_id user.id and model_kind user.kind' do
      expect(graphed_node).to be
      expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(1)
      graph_agent = subject.graph_node
      expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(1)
      expect(graph_agent).to be
      expect(graph_agent.model_id).to eq(subject.id)
      expect(graph_agent.model_kind).to eq(subject.kind)
    end
  end

  context 'when model is deleted' do
    before do
      expect(subject).to be
      expect(subject.graph_node).to be
    end
    if logically_deleted
      it 'should logicially delete graph_node with the model' do
        expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(1)
        subject.update_attribute(:is_deleted, true)
        expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(1)
        expect(subject.graph_node).to be
        expect(subject.graph_node.is_deleted).to be_truthy
      end
    else
      it 'should destroy graph_node with the model' do
        expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(1)
        subject.destroy
        expect(graph_node_name.constantize.where(model_id: subject.id, model_kind: subject.kind).count).to eq(0)
      end
    end
  end
end
