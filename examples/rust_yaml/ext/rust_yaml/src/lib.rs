use magnus::{
    encoding::{CType, RbEncoding},
    method,
    function,
    prelude::*,
    Error, RString, Ruby,
};
use serde_yaml::Value;

fn parse_and_print_yaml(rb_self: RString) -> Result<bool, Error> {
    let yaml_str = rb_self.to_string()?;
    
    match serde_yaml::from_str::<Value>(&yaml_str) {
        Ok(yaml_value) => {
            println!("Parsed YAML content:");
            println!("{:#?}", yaml_value);
            Ok(true)
        },
        Err(e) => Err(Error::new(magnus::exception::runtime_error(), e.to_string())),
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let class = ruby.define_class("String", ruby.class_object())?;
    class.define_method("parse_and_print_yaml?", method!(parse_and_print_yaml, 0))?;
    Ok(())
}