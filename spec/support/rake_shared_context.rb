require "rake"

shared_context "rake" do
  let(:rake) { Rake::Application.new }
  let(:task_name) { self.class.top_level_description }
  let(:task_path) { "lib/tasks/#{task_name.split(":").first}" }
  subject { rake[task_name] }

  def invoke_task(expected_stdout: //, expected_stderr: //)
    expect {
      expect {
        subject.invoke
      }.to output(expected_stderr).to_stderr
    }.to output(expected_stdout).to_stdout
  end

  def loaded_files_excluding_current_rake_file
    $".reject {|file| file == Rails.root.join("#{task_path}.rake").to_s }
  end

  before do
    Rake.application = rake
    Rake.application.rake_require(task_path, [Rails.root.to_s], loaded_files_excluding_current_rake_file)

    Rake::Task.define_task(:environment)
  end
end

shared_examples 'a queued job worker' do |job_class_sym|
  let(:job_class) { send(job_class_sym) }
  it {
    expected_workers = []
    this_worker = job_class.job_wrapper
    expected_workers << this_worker
    expect(job_class).to receive(:job_wrapper).and_return(this_worker)
    expect(expected_workers).not_to be_empty
    mocked_sneakers_runner = instance_double(Sneakers::Runner)
    expect(Sneakers::Runner).to receive(:new)
      .with(expected_workers)
      .and_return(mocked_sneakers_runner)
    expect(mocked_sneakers_runner).to receive(:run).and_return(true)
    invoke_task
  }
end
