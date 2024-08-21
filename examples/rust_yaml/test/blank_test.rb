# frozen_string_literal: true

require "test/unit"
require_relative "../lib/rust_yaml"

class YamlParseTest < Test::Unit::TestCase
  def test_parse_yaml
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

    result = yaml_string.parse_yaml

    assert_instance_of(Hash, result)
    assert_equal("John Doe", result[:name])
    assert_equal(30, result[:age])
    assert_equal(["reading", "swimming"], result[:hobbies])
    assert_equal({street: "123 Main St", city: "Anytown", country: "USA"}, result[:address])
  end

  def test_parse_invalid_yaml
    invalid_yaml = "{ invalid: yaml: content }"

    assert_raise(RuntimeError, "Invalid YAML content should raise an error") do
      invalid_yaml.parse_yaml
    end
  end
end