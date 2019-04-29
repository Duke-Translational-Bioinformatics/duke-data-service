require "rake"

shared_context "rake" do
  let(:rake) { Rake.application }
  let(:task_name) { self.class.top_level_description }
  subject { rake[task_name] }

  def invoke_task(expected_stdout: //, expected_stderr: //)
    expect {
      expect {
        subject.invoke
      }.to output(expected_stderr).to_stderr
    }.to output(expected_stdout).to_stdout
  end

  # This allows tasks to be invoked more than once.
  after do
    subject.reenable
  end
end

shared_context 'with env_override' do
  let(:env_override) { {} }
  before(:each) do
    env_override.each do |env_key, env_val|
      ENV[env_key] = env_val.to_s
    end
  end
  after(:each) do
    env_override.keys.each do |env_key|
      ENV.delete(env_key)
    end
  end
end
