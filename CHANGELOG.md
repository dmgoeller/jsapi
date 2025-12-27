# Change log

## 2.0 (2025-12-27)

### New features

#### API Actions

API actions can now be implemented by `api_action` or `api_action!`.

```ruby
api_operation 'foo' do
  # Define API operation here
end

api_action :foo, action: :index

def foo(api_params)
  # Implement API operation here
end
```

#### API Callbacks

The `api_operation` and `api_operation!` methods now trigger `api_before_processing` and
`api_before_rendering` callbacks.

```ruby
api_before_processing :foo

def foo(api_params)
  # Implement callback here
end
```

#### Support of "text/plain" media type

The `api_operation` and `api_operation!` methods now render the textual representation of
the object returned by the block when the media type of the response is `text/plain`.

#### Content Negotiation

Request body and responses can now have different types of content.

When producing a response the most appropriate content is selected.

#### OpenAPI

The data form and serialized form of an example can now be specified together.

Callbacks now allow multiple operations per expression.

### Changes

The micro versions of OpenAPI 3.0 and 3.1 are updated to 3.0.4 and 3.1.2.

### Breaking changes

#### OpenAPI and JSON Schema documents

All keys in generated OpenAPI and JSON Schema documents are now strings.

#### Request bodies and responses

The content type of request bodies and responses can only be defined as a keyword argument.

```ruby
# Ok:
response content_type: 'application/json'
```

```ruby
# Raises an error:
response do
  content_type 'application/json'
end
```

#### Examples

External examples are now specified by the `external_value` keyword.

```ruby
# Jsapi 1.x:
example value: 'https:://foo.bar/example' external: true
```

```ruby
# Jsapi 2.0:
example external_value: 'https:://foo.bar/example'
```

#### Callbacks

To allow multiple operations to be specified per expression, the definition of a callback
has been changed as below.

```ruby
# Jsapi 1.x:
callback 'foo' do
  operation '{$request.query.bar}', method: 'get'
end
```

```ruby
# Jsapi 2.0:
callback 'foo' do
  expression '{$request.query.bar}' do
    operation 'get'
  end
end
```

## 1.4 (2025-11-15)

### New Features

Operations can now be grouped by path. Therefore, it is possible to specify
a path name only once, even if there are multiple operations for it.

## 1.3 (2025-11-02)

### New Features

The new OpenAPI version 3.2 is supported, in particalur:

  - Streaming of responses in JSON sequence text format as specified by RFC 7464
  - Defining of parameters representing the entire query string
  - Specifying the default mapping of a discriminator

### Breaking changes

- The default location of API definitions has been changed from `app/api_defs` to
  `jsapi/api_defs` to prevent API definitions to be loaded automatically by
  Zeitwerk.

## 1.2 (2025-08-30)

### New features

Instances of `Jsapi::Model::Base` can be converted to serializable hashes.

## 1.1.1 (2025-06-19)

### Changes

`Jsapi::Meta::Parameter::Base#explode_parameter` no longer fails when a property refers
a schema.

##  1.1 (2025-04-06)

### Changes

The `api_operation` and `api_operation!` controller methods renders a response only if
the content type is a JSON MIME type.

## 1.0 (2024-11-01)

### Changes

- The micro version of OpenAPI 3.1 is updated from 3.1.0 to 3.1.1.

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
