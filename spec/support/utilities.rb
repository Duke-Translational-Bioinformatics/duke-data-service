shared_context 'requires let variables' do |let_variable_symbols|
  before do
    expect(let_variable_symbols).to be_an Array
    let_variable_symbols.each do |expected_let_variable|
      expect(methods).to include expected_let_variable
    end
  end
end
