shared_examples 'a JobTracking resource' do
  it {
    expect(described_class).to include(JobTracking)
  }
end
