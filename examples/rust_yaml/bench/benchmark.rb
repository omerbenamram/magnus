require 'benchmark'
require 'yaml'
require 'base64'
require_relative '../lib/rust_yaml'

def generate_small_yaml
  <<~YAML
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
    data: !binary SGVsbG8sIFdvcmxkIQ==
  YAML
end

def generate_large_yaml(size)
  items = (1..size).map do |i|
    <<~YAML
      item_#{i}:
        id: #{i}
        name: Name #{i}
        active: #{i.even?}
        score: #{rand * 100}
        tags: 
          - tag#{i}_1
          - tag#{i}_2
          - tag#{i}_3
        nested:
          key1: value#{i}_1
          key2: value#{i}_2
          key3:
            subkey1: subvalue#{i}_1
            subkey2: subvalue#{i}_2
        array:
          - element1
          - element2
          - element3
        binary_data: !binary #{Base64.strict_encode64("Binary data for item #{i}")}
    YAML
  end
  
  "---\n" + items.join("\n")
end

small_yaml = generate_small_yaml
large_yaml = generate_large_yaml(1000)

# Parse YAML strings to Ruby objects for dumping benchmarks
small_ruby_object = YAML.safe_load(small_yaml, aliases: true)
large_ruby_object = YAML.safe_load(large_yaml, aliases: true)

# Number of iterations
small_n = 10_000
large_n = 100

Benchmark.bmbm do |x|
  x.report("Ruby YAML.safe_load (small)") do
    small_n.times { YAML.safe_load(small_yaml, aliases: true) }
  end

  x.report("Rust parse_yaml (small)") do
    small_n.times { small_yaml.parse_yaml }
  end

  x.report("Ruby YAML.safe_load (large)") do
    large_n.times { YAML.safe_load(large_yaml, aliases: true) }
  end

  x.report("Rust parse_yaml (large)") do
    large_n.times { large_yaml.parse_yaml }
  end

  x.report("Ruby YAML.dump (small)") do
    small_n.times { YAML.dump(small_ruby_object) }
  end

  x.report("Rust to_yaml (small)") do
    small_n.times { small_ruby_object.to_yaml }
  end

  x.report("Ruby YAML.dump (large)") do
    large_n.times { YAML.dump(large_ruby_object) }
  end

  x.report("Rust to_yaml (large)") do
    large_n.times { large_ruby_object.to_yaml }
  end
end