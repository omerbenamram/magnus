use magnus::{
    method,
    prelude::*,
    Error, RString, Ruby, RHash, RArray, Symbol, Value, Numeric
};
use serde_yaml::Value as YamlValue;

fn yaml_to_ruby(ruby: &Ruby, value: &YamlValue) -> Result<magnus::Value, Error> {
    match value {
        YamlValue::Null => Ok(ruby.eval("nil")?),
        YamlValue::Bool(b) => Ok(ruby.eval(&format!("{}", b))?),
        YamlValue::Number(n) => {
            match n {
                n if n.is_i64() => Ok(ruby.integer_from_i64(n.as_i64().unwrap()).as_value()),
                n if n.is_u64() => Ok(ruby.integer_from_u64(n.as_u64().unwrap()).as_value()),
                n if n.is_f64() => Ok(ruby.float_from_f64(n.as_f64().unwrap()).as_value()),
                _ => Err(Error::new(magnus::exception::runtime_error(), "Unsupported number type")),
            }
        },
        YamlValue::String(s) => Ok(RString::new(s).as_value()),
        YamlValue::Sequence(seq) => {
            let array = RArray::new();
            for item in seq {
                array.push(yaml_to_ruby(ruby, item)?)?;
            }
            Ok(array.as_value())
        },
        YamlValue::Mapping(map) => {
            let hash = RHash::new();
            for (k, v) in map {
                let key = match k {
                    YamlValue::String(s) => Symbol::new(s).as_value(),
                    _ => yaml_to_ruby(ruby, k)?,
                };
                hash.aset(key, yaml_to_ruby(ruby, v)?)?;
            }
            Ok(hash.as_value())
        },
        YamlValue::Tagged(_) => todo!(),
    }
}

fn parse_yaml(ruby: &Ruby, rb_self: RString) -> Result<Value, Error> {
    let yaml_str = rb_self.to_string()?;
    
    match serde_yaml::from_str::<YamlValue>(&yaml_str) {
        Ok(yaml_value) => yaml_to_ruby(ruby, &yaml_value),
        Err(e) => Err(Error::new(magnus::exception::runtime_error(), e.to_string())),
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let class = ruby.define_class("String", ruby.class_object())?;
    class.define_method("parse_yaml", method!(parse_yaml, 0))?;
    Ok(())
}