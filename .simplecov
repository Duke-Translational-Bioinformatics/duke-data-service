class SimpleCov::Formatter::MergedFormatter
  def format(result)
    SimpleCov::Formatter::HTMLFormatter.new.format(result) # for the simplecov report
  end
end

SimpleCov.start 'rails' do
  SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
end
