# Change log

##  1.1 (2025-04-06)

### Changes

- The `api_operation` and `api_operation!` controller methods renders a response only if
  the content type is a JSON MIME type.

## 1.0 (2024-11-01)

### Changes

- Updated OpenAPI 3.1.0 to 3.1.1.

- `openapi_document` raises an exception when trying to produce an OpenAPI 2.0 document
  containing a reusable object parameter.

## 0.9.2 (2024-10-24)

### Changes

- The order of operations and schemas in OpenAPI documents has been changed.

## 0.9.1 (2024-10-18)

### New features

- API definitions can be imported from files.

## 0.9.0 (2024-10-12)

### Breaking changes

- `openapi` has been removed from the DSL. All declarations that were previously specified in
  an `openapi` block are now specified directly in an `api_definitions` block or on top level
  with prefix `api_`. This allows OpenAPI objects to be inherited/included like API components.

### Changes

- The OpenAPI 2.0 base path and OpenAPI 3.x server objects are derrived from a controller's
  module name by default.

## 0.8.0 (2024-09-29)

### Changes

- Serialization of responses has been improved.

## 0.7.3 (2024-09-25)

### Changes

- The `Jsapi::Model` module has been refactored.

## 0.7.2 (2024-09-24)

### Changes

- Performance improvements

## 0.7.0 (2024-09-21)

### New features

- API components are inherited from parent class.

## 0.6.2 (2024-09-17)

### Changes

- The value of a discriminator property can be `false`.

## 0.6.1 (2024-09-17)

### New features

- Objects within requests may include additional properties as specified by OpenAPI.

- Responses can also be created from hashes whose keys are symbols or strings.

- The general default values of parameters and properties can be configured per type.

- The content type of a request body or response can be specified by the `:content_type`
  keyword.

### Breaking changes

- The `attributes`, `attribute?` and `[]` methods of the `Jsapi::Model::Base` retrieve
  parameters and properties by the original name instead of the snake case form.

- The `:consumes` and `:produces` keywords have been removed. The MIME types are now
  derived from the content types of the request bodies and responses.

- Starting with this version, reusable OpenAPI example objects are defined under `openapi`
  instead of `api_definitions`.

### Changes

- `Jsapi::Controller::Response#to_json` doesn't raise a `NoMethodError` when the method to
  read a property value isn't defined.

## 0.5.0 (2024-08-31)

### Changes

- Property values can be read by a sequence of methods specified as an array or a string
  like `foo.bar`.

- Validation errors can be added to error responses using the `errors` method of a
  `Jsapi::Controller::ParametersInvalid` exception.

## 0.4.1 (2024-08-21)

- Changes

- Strong parameter validation ignores the `:format` parameter.

## 0.4.0 (2024-08-21)

### New features

- Implicitly rescued exceptions can be sent to `on_rescue` callbacks.

- OpenAPI header objects are supported from this version.

## 0.3.0 (2024-07-14)

### Breaking changes

- Parameter and property names in camel case are converted to method names in snake case.

### New features

- Responses may contain additional properties as specified by OpenAPI.

- OpenAPI extensions are supported from this version.

## 0.2.0 (2024-07-05)

### Breaking changes

- The `schema` method no longer takes the `schema` keyword to refer another schema, for
  example `schema 'foo', schema: 'bar'`. Instead, the `ref` keyword can be used,
  for example `schema 'foo', ref: 'bar'`.

- `api_operation!` raises an `Jsapi::Controller::ParametersInvalid` instead of a
  `ParserError` if a string can't be converted to a `Date` or `DateTime`.

### Changes

- The `:format` keyword is no longer restricted to `"date"` and `"date-time"`.

- A parameter or property value is casted to an instance of `ActiveSupport::Duration` when
  type is `"string"` and format is `"duration"`.

- The `schemes`, `host` and `basPath` fields of an OpenAPI 2.0 object are taken from the
  URL of the first server object if they are not specified explicitly.

## 0.1.2 (2024-06-28)

### Changes

- Added meta data to gemspec.

## 0.1.1 (2024-05-27)

Initial version
