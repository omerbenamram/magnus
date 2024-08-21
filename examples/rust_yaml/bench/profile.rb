require 'yaml'
require 'date'
require 'ruby-prof'
require 'base64'
require_relative '../lib/rust_yaml'

def generate_small_yaml
  <<~YAML
    ---
    name: John Doe
    age: 30
    date: !timestamp 2023-04-14
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
        date: !timestamp #{Date.today + i}
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

def profile_parser(name, yaml, iterations, &block)
  # Warm-up run
  block.call(yaml)

  profile = RubyProf::Profile.new
  result = profile.profile do
    iterations.times { block.call(yaml) }
  end

  printer = RubyProf::FlatPrinter.new(result)
  File.open("#{name}_profile.txt", "w") do |file|
    printer.print(file)
  end
end

def profile_dumper(name, ruby_object, iterations, &block)
  # Warm-up run
  block.call(ruby_object)

  profile = RubyProf::Profile.new
  result = profile.profile do
    iterations.times { block.call(ruby_object) }
  end

  printer = RubyProf::FlatPrinter.new(result)
  File.open("#{name}_dump_profile.txt", "w") do |file|
    printer.print(file)
  end
end

# Parse small YAML to Ruby object
small_ruby_object = YAML.safe_load(small_yaml, permitted_classes: [Date], aliases: true)

# Parse large YAML to Ruby object
large_ruby_object = YAML.safe_load(large_yaml, permitted_classes: [Date], aliases: true)

# Profile small YAML parsing
profile_parser("ruby_small", small_yaml, 10_000) { |y| YAML.safe_load(y, permitted_classes: [Date], aliases: true) }
profile_parser("rust_small", small_yaml, 10_000) { |y| y.parse_yaml }

# Profile large YAML parsing
profile_parser("ruby_large", large_yaml, 100) { |y| YAML.safe_load(y, permitted_classes: [Date], aliases: true) }
profile_parser("rust_large", large_yaml, 100) { |y| y.parse_yaml }

# Profile small YAML dumping
profile_dumper("ruby_small", small_ruby_object, 10_000) { |obj| YAML.dump(obj) }
profile_dumper("rust_small", small_ruby_object, 10_000) { |obj| obj.to_yaml }

# Profile large YAML dumping
profile_dumper("ruby_large", large_ruby_object, 100) { |obj| YAML.dump(obj) }
profile_dumper("rust_large", large_ruby_object, 100) { |obj| obj.to_yaml }

puts "Profiling complete. Results written to *_profile.txt and *_dump_profile.txt files."