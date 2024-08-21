# frozen_string_literal: true

require "test/unit"
require_relative "../lib/rust_yaml"
require "date"

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

  def test_parse_yaml_with_tagged_values
    yaml_string = <<~YAML
      ---
      date: !timestamp 2023-04-14
      version: !semver 1.2.3
      data: !binary 
        SGVsbG8sIFdvcmxkIQ==
    YAML

    result = yaml_string.parse_yaml

    assert_instance_of(Hash, result)
    assert_equal({tag: :timestamp, value: "2023-04-14"}, result[:date])
    assert_equal({tag: :semver, value: "1.2.3"}, result[:version])
    assert_equal({tag: :binary, value: "SGVsbG8sIFdvcmxkIQ=="}, result[:data])
  end

  def test_parse_invalid_yaml
    invalid_yaml = "{ invalid: yaml: content }"

    assert_raise(RuntimeError, "Invalid YAML content should raise an error") do
      invalid_yaml.parse_yaml
    end
  end

  def test_to_yaml
    ruby_object = {
      name: "Jane Doe",
      age: 28,
      hobbies: ["coding", "hiking"],
      address: {
        street: "456 Elm St",
        city: "Techville",
        country: "Canada"
      }
    }

    yaml_string = ruby_object.to_yaml
    parsed_yaml = yaml_string.parse_yaml

    assert_equal(ruby_object, parsed_yaml)
  end

  def test_to_yaml_serialization_with_dates
    ruby_object = {
      name: "Jane Doe",
      birthdate: Date.new(1990, 1, 1),
      important_dates: [
        Date.new(2023, 4, 14),
        Date.new(2023, 12, 25)
      ],
      nested: {
        date: Date.new(2024, 1, 1)
      }
    }

    yaml_string = ruby_object.to_yaml

    # Ensure the generated YAML string contains the correct date format
    assert_match(/name: Jane Doe/, yaml_string)
    assert_match(/birthdate: 1990-01-01/, yaml_string)
    assert_match(/important_dates:/, yaml_string)
    assert_match(/- 2023-04-14/, yaml_string)
    assert_match(/- 2023-12-25/, yaml_string)
    assert_match(/nested:/, yaml_string)
    assert_match(/date: 2024-01-01/, yaml_string)
  end

  def test_parse_yaml_deserialization_with_dates
    yaml_string = <<~YAML
      ---
      name: Jane Doe
      birthdate: 1990-01-01
      important_dates:
        - 2023-04-14
        - 2023-12-25
      nested:
        date: 2024-01-01
    YAML

    parsed_yaml = yaml_string.parse_yaml

    assert_equal("Jane Doe", parsed_yaml[:name])
    assert_instance_of(Date, parsed_yaml[:birthdate])
    assert_equal(Date.new(1990, 1, 1), parsed_yaml[:birthdate])
    assert_instance_of(Array, parsed_yaml[:important_dates])
    assert_equal([Date.new(2023, 4, 14), Date.new(2023, 12, 25)], parsed_yaml[:important_dates])
    assert_instance_of(Hash, parsed_yaml[:nested])
    assert_instance_of(Date, parsed_yaml[:nested][:date])
    assert_equal(Date.new(2024, 1, 1), parsed_yaml[:nested][:date])
  end
end