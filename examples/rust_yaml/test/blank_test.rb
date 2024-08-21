# frozen_string_literal: true

require "test/unit"
require_relative "../lib/rust_yaml"
require 'stringio'

puts String.instance_methods.include?(:parse_and_print_yaml)

class YamlParseTest < Test::Unit::TestCase
  def test_parse_and_print_yaml
    yaml_string = <<~YAML
      ---
      name: John Doe
      age: 30
      hobbies:
        - reading
        - swimming
      address:
        street: 123 Main St
        city: Anytown
        country: USA
    YAML

    output = capture_output do
      yaml_string.parse_and_print_yaml?
    end

    assert_match(/Parsed YAML content:.*name: "John Doe".*age: 30.*hobbies:.*- "reading".*- "swimming".*address:.*street: "123 Main St".*city: "Anytown".*country: "USA".*/m, output)
  end

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def test_parse_invalid_yaml
    invalid_yaml = "{ invalid: yaml: content }"

    assert_raise(RuntimeError, "Invalid YAML content should raise an error") do
      invalid_yaml.parse_and_print_yaml
    end
  end
end