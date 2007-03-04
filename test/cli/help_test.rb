require "#{File.dirname(__FILE__)}/../utils"
require 'capistrano/cli/help'

class CLIHelpTest < Test::Unit::TestCase
  class MockCLI
    attr_reader :options, :called_original

    def initialize
      @options = {}
      @called_original = false
    end

    def execute_requested_actions(config)
      @called_original = config
    end

    include Capistrano::CLI::Help
  end

  def setup
    @cli = MockCLI.new
    @ui = stub("ui", :output_cols => 80)
    MockCLI.stubs(:ui).returns(@ui)
  end

  def test_execute_requested_actions_without_tasks_or_explain_should_call_original
    @cli.execute_requested_actions(:config)
    @cli.expects(:task_list).never
    @cli.expects(:explain_task).never
    assert_equal :config, @cli.called_original
  end

  def test_execute_requested_actions_with_tasks_should_call_task_list
    @cli.options[:tasks] = true
    @cli.expects(:task_list).with(:config)
    @cli.expects(:explain_task).never
    @cli.execute_requested_actions(:config)
    assert !@cli.called_original
  end

  def test_execute_requested_actions_with_explain_should_call_explain_task
    @cli.options[:explain] = "deploy_with_niftiness"
    @cli.expects(:task_list).never
    @cli.expects(:explain_task).with(:config, "deploy_with_niftiness")
    @cli.execute_requested_actions(:config)
    assert !@cli.called_original
  end

  def test_task_list_with_no_tasks_should_emit_warning
    config = mock("config", :task_list => [])
    @cli.expects(:warn)
    @cli.task_list(config)
  end

  def test_task_list_should_query_all_tasks_in_all_namespaces
    expected_max_len = 80 - 3 - MockCLI::LINE_PADDING
    task_list = [task("c"), task("g", "c:g"), task("b", "c:b"), task("a")]
    task_list.each { |t| t.expects(:brief_description).with(expected_max_len).returns(t.fully_qualified_name) }
  
    config = mock("config")
    config.expects(:task_list).with(:all).returns(task_list)
    @cli.stubs(:puts)
    @cli.task_list(config)
  end

  def test_task_list_should_never_use_less_than_MIN_MAX_LEN_chars_for_descriptions
    @ui.stubs(:output_cols).returns(20)
    t = task("c")
    t.expects(:brief_description).with(30).returns("hello")
    config = mock("config", :task_list => [t])
    @cli.stubs(:puts)
    @cli.task_list(config)
  end

  def test_explain_task_should_warn_if_task_does_not_exist
    config = mock("config", :find_task => nil)
    @cli.expects(:warn).with { |s,| s =~ /`deploy_with_niftiness'/ }
    @cli.explain_task(config, "deploy_with_niftiness")
  end

  def test_explain_task_with_task_that_has_no_description_should_emit_stub
    t = mock("task", :description => "")
    config = mock("config")
    config.expects(:find_task).with("deploy_with_niftiness").returns(t)
    @cli.stubs(:puts)
    @cli.expects(:puts).with("There is no description for this task.")
    @cli.explain_task(config, "deploy_with_niftiness")
  end

  def test_explain_task_with_task_should_format_description
    t = stub("task", :description => "line1\nline2\n\nline3")
    config = mock("config", :find_task => t)
    @cli.stubs(:puts)
    @cli.explain_task(config, "deploy_with_niftiness")
  end

  private

    def task(name, fqn=name)
      stub("task", :name => name, :fully_qualified_name => fqn)
    end
end