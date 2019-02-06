require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  let(:gateway_exchange_name) { 'test.'+Faker::Internet.slug }
  let(:gateway_exchange) { channel.exchange(gateway_exchange_name, type: :fanout, durable: true) }
  let(:distributor_exchange_name) { 'active_jobs' }
  let(:distributor_exchange_type) { :direct }
  let(:distributor_exchange) { channel.exchange(distributor_exchange_name, type: distributor_exchange_type, durable: true) }

  let(:bunny_session) { Sneakers::CONFIG[:connection] }
  let(:channel) { bunny_session.channel }

  include_context 'with sneakers'
  before do
    Sneakers.configure(exchange: gateway_exchange_name, timeout_job_after: 1, retry_timeout: 60000, retry_max_times: 1)
  end
  after do
    bunny_session.with_channel do |channel|
      if channel.respond_to? :exchange_delete
        channel.exchange_delete(gateway_exchange_name)
        channel.exchange_delete(distributor_exchange_name)
      end
    end
  end

  it { is_expected.to be_a ActiveJob::Base }
  it { expect{described_class.perform_now}.to raise_error(NotImplementedError) }

  it { expect(ENV['ACTIVE_JOB_QUEUE_ADAPTER']).to be_nil }
  it { expect(ActiveJob::Base.queue_adapter).to be_a(ActiveJob::QueueAdapters::SneakersAdapter) }

  it { expect(described_class).to respond_to(:create_bindings) }
  it {
    expect(described_class).to respond_to(:should_be_registered_worker?)
    expect(described_class.should_be_registered_worker?).to be_truthy
  }

  it_behaves_like 'a JobTracking resource'

  describe 'default configuration' do
    subject { Sneakers::CONFIG }
    it {
      expect(subject[:workers]).to eq 1
      expect(subject[:start_worker_delay]).to eq 10
      expect(subject[:prefetch]).to eq 1
      expect(subject[:threads]).to eq 1
    }
  end

  describe '::create_bindings' do
    let(:create_bindings) { described_class.create_bindings }
    it { expect(bunny_session.exchange_exists?(gateway_exchange_name)).to be_falsey }
    it { expect(bunny_session.exchange_exists?(distributor_exchange_name)).to be_falsey }
    context 'once called' do
      before { create_bindings }
      it { expect(bunny_session.exchange_exists?(gateway_exchange_name)).to be_truthy }
      it { expect(gateway_exchange.type).to eq(Sneakers::CONFIG[:exchange_options][:type]) }
      it { expect(gateway_exchange).to be_durable }

      it { expect(bunny_session.exchange_exists?(distributor_exchange_name)).to be_truthy }
      it { expect(distributor_exchange.type).to eq(:direct) }
      it { expect(distributor_exchange).to be_durable }


      it { expect(distributor_exchange).to be_bound_to(gateway_exchange) }
    end
  end

  it { expect(described_class).to respond_to(:job_wrapper) }
  describe '::job_wrapper' do
    it { expect{described_class.job_wrapper}.to raise_error NotImplementedError}
  end

  context 'child_class' do
    let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
    let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }
    let(:child_class_queue_name) { Faker::Internet.slug(nil, '_') }
    let(:prefixed_queue_name) { "#{prefix}#{prefix_delimiter}#{child_class_queue_name}"}
    # Maxretry queue and exchange names
    let(:error_exchange_name) { prefixed_queue_name + '.dlx' }
    let(:error_queue_name) { prefixed_queue_name + '.error' }
    let(:child_class_queue) {
      channel.queue(prefixed_queue_name,
        durable: true,
        arguments: {
          'x-dead-letter-exchange' => "#{child_class.queue_name}.dlx",
          'x-dead-letter-routing-key' => "#{child_class.queue_name}"
        },
      )
    }
    let(:child_class_name) {|example| "application_job_spec#{example.metadata[:scoped_id].gsub(':','x')}_job".classify }
    let(:child_class) {
      klass_queue_name = child_class_queue_name
      Object.const_set(child_class_name, Class.new(described_class) do
        queue_as klass_queue_name
        @run_count = 0
        def perform(an_arg=nil)
          self.class.run_count = self.class.run_count.next
        end
        def self.run_count=(val)
          @run_count = val
        end
        def self.run_count
          @run_count
        end
        def self.should_be_registered_worker?
          false
        end
      end)
    }
    it { expect(child_class.transaction_key).to eq(child_class.queue_name) }

    before { expect{ActiveJob::Base.queue_adapter = :sneakers}.not_to raise_error }
    after do
      bunny_session.with_channel do |channel|
        if channel.respond_to? :queue_delete
          channel.queue_delete(prefixed_queue_name)
          channel.queue_delete(error_queue_name)
        end
        if channel.respond_to? :exchange_delete
          channel.exchange_delete(error_exchange_name)
        end
      end
    end
    it { expect(prefix).not_to be_nil }
    it { expect(prefix_delimiter).not_to be_nil }
    it { expect(child_class.queue_name).to eq(prefixed_queue_name) }

    it { expect{child_class.perform_now}.not_to raise_error }

    it { expect(child_class).to respond_to :run_count }
    describe '::run_count' do
      it { expect(child_class.run_count).to eq 0 }
      context 'after perform_now call' do
        before { child_class.perform_now }
        it { expect(child_class.run_count).to eq 1 }
      end
    end

    context 'without job_wrapper running' do
      it { expect(bunny_session.queue_exists?(prefixed_queue_name)).to be_falsey }
      it { expect{child_class.perform_later}.to raise_error(described_class::QueueNotFound, "Queue #{prefixed_queue_name} does not exist") }

      context "when ENV[''] is set" do
        include_context 'with env_override'
        let(:env_override) { {
          'SNEAKERS_SKIP_QUEUE_EXISTS_TEST' => 'yes'
        } }
        it { expect{child_class.perform_later}.not_to raise_error }
      end

      context 'when not using sneakers' do
        before { expect{ActiveJob::Base.queue_adapter = :inline}.not_to raise_error }
        it { expect{child_class.perform_later}.not_to raise_error }
      end
    end

    describe '::job_wrapper' do
      let(:job_wrapper) { child_class.job_wrapper }
      let(:queue_opts) {{
        arguments: {
          'x-dead-letter-exchange' => "#{child_class.queue_name}.dlx",
          'x-dead-letter-routing-key' => "#{child_class.queue_name}"
        },
        exchange: distributor_exchange_name,
        exchange_type: distributor_exchange_type
      }}
      it { expect(job_wrapper).to be_a Class }
      it { expect(job_wrapper.ancestors).to include ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper }
      it { expect(job_wrapper.queue_name).to eq child_class.queue_name }
      it { expect(job_wrapper.queue_opts).to include queue_opts }
      it 'calls ::create_bindings' do
        expect(described_class).to receive(:create_bindings)
        job_wrapper
      end
      it { expect(bunny_session.queue_exists?(prefixed_queue_name)).to be_falsey }
      context 'instance backoff_function' do
        let(:job_wrapper_instance) { child_class.job_wrapper.new }
        let(:backoff_function) { job_wrapper_instance.opts[:backoff_function] }
        let(:backoff_seq) { [1, 2, 4, 8, 16] }
        it { expect(backoff_function).to respond_to(:call).with(1).argument }
        # 2^x
        it { expect(backoff_function.call(0)).to eq(backoff_seq[0]) }
        it { expect(backoff_function.call(1)).to eq(backoff_seq[1]) }
        it { expect(backoff_function.call(2)).to eq(backoff_seq[2]) }
        it { expect(backoff_function.call(3)).to eq(backoff_seq[3]) }
        it { expect(backoff_function.call(4)).to eq(backoff_seq[4]) }
      end
      context 'instance created and run' do
        let(:job_wrapper_instance) { child_class.job_wrapper.new }
        before { job_wrapper_instance.run }

        it { expect(job_wrapper_instance.opts[:handler]).to eq SneakersHandlers::ExponentialBackoffHandler }
        it { expect(bunny_session.queue_exists?(prefixed_queue_name)).to be_truthy }
        it { expect(bunny_session.exchange_exists?(distributor_exchange_name)).to be_truthy }
        it { expect(child_class_queue).to be_bound_to(distributor_exchange) }
        it { expect(bunny_session.queue_exists?(error_queue_name)).to be_truthy }
        it { expect(bunny_session.exchange_exists?(error_exchange_name)).to be_truthy }
        it { expect{child_class.perform_later}.not_to raise_error }
        it { expect{
          child_class.perform_later
          begin
            sleep 0.1
          end while Thread.list.count {|t| t.status == "run"} > 1
        }.to change{child_class.run_count}.by(1) }

        context 'when stopped' do
          before { job_wrapper_instance.stop }
          it { expect{child_class.perform_later}.to change{child_class_queue.message_count}.by(1) }
          context 'creates one Sneakers::Publisher' do
            before { expect(Sneakers::Publisher).to receive(:new).and_call_original }
            it 'when called once' do
              expect{child_class.perform_later}.not_to raise_error
            end
            it 'when called twice' do
              expect{child_class.perform_later}.not_to raise_error
              expect{child_class.perform_later}.not_to raise_error
            end
          end
        end
      end
    end
  end
end
