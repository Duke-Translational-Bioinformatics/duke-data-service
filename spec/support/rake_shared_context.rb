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
