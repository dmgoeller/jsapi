# Jsapi

Easily build OpenAPI compliant APIs with Rails.

## Why Jsapi?

Without Jsapi, complex API applications typically use in-memory models to read requests and
serializers to write responses. When using OpenAPI for documentation purposes, this is done
separatly.

Jsapi brings all this together. The models to read requests, the serialization of objects and
the optional OpenAPI documentation are based on the same API definition. This significantly
reduces the workload and ensures that the OpenAPI documentation is consistent with the
server-side implementation of the API.

Jsapi supports OpenAPI 2.0, 3.0 and 3.1.

## Installation

Add the following line to `Gemfile` and run `bundle install`.

```ruby
gem 'jsapi'
```

## Getting started

Start by adding a route for the API endpoint. For example, a non-resourceful route for a
simple echo endpoint can be defined as below.

```ruby
# config/routes.rb

get 'echo', to: 'echo#index'
```

Specify the operation to be bound to the API endpoint in `app/api_defs/echo.rb`:

```ruby
# app/api_defs/echo.rb

operation path: '/echo' do
  parameter 'call', type: 'string', existence: true
  response 200, type: 'object' do
    property 'echo', type: 'string'
  end
  response 400, type: 'object' do
    property 'status', type: 'integer'
    property 'message', type: 'string'
  end
end
```

Note that `existence: true` declares the `call` parameter to be required.

Create a controller that inherits from `Jsapi::Controller::Base`:

```ruby
# app/controllers/echo_controller.rb

class EchoController < Jsapi::Controller::Base
  def index
    api_operation! status: 200 do |api_params|
      {
        echo: "#{api_params.call}, again"
      }
    end
  end
end
```

Note that `api_operation!` renders the JSON representation of the object returned by the block.
This can be a hash or an object providing corresponding methods for all properties of the
response.

When the required `call` parameter is missing or the value of `call` is empty, `api_operation!`
raises a `Jsapi::Controller::ParametersInvalid` error. To rescue such exceptions, add an
`rescue_from` directive to `app/api_defs/echo.rb`:

```ruby
# app/api_defs/echo.rb

rescue_from Jsapi::Controller::ParametersInvalid, with: 400
```

To create the OpenAPI documentation for the `echo` operation, add another route, an `info`
directive and the controller action to produce OpenAPI documents, for example:

```ruby
# config/routes.rb

get 'echo/openapi', to: 'echo#openapi'
```

```ruby
# app/api_defs/echo.rb

info title: 'Echo', version: '1'
```

```ruby
# app/controllers/echo_controller.rb

class EchoController < Jsapi::Controller::Base
  def openapi
    render(json: api_definitions.openapi_document(params[:version]))
  end
end
```

The API defintions, controller and routes for the `echo` API operation look like:

- [app/api_defs/echo.rb](examples/echo/app/api_defs/echo.rb)
- [app/controllers/echo_controller.rb](examples/echo/app/controllers/echo_controller.rb)
- [config/routes.rb](/examples/echo/config/routes.rb)

An instance of the `EchoController` class responds to `GET /echo?call=Hello` with HTTP status
code 200. The response body is:

```json
{
  "echo": "Hello, again"
}
```

When the `call` parameter is missing or the value of `call` is empty, a response with HTTP
status code 400 and the following body is produced:

```json
{
  "status": 400,
  "message": "'call' can't be blank."
}
```

`GET /echo/openapi?version={2.0|3.0|3.1}` produces the following OpenAPI documents:

- [openapi-2.0.json](examples/echo/doc/openapi-2.0.json)
- [openapi-3.0.json](examples/echo/doc/openapi-3.0.json)
- [openapi-3.1.json](examples/echo/doc/openapi-3.1.json)

## Jsapi DSL

Everything needed to build an API is defined by a DSL whose vocabulary is based on OpenAPI /
JSON Schema. This DSL can be used in any controller inheriting from `Jsapi::Controller::Base`
as well as any class extending `Jsapi::DSL`. To avoid naming conflicts with other libraries,
all top-level directives start with `api_`. Therefore, the API definitions of the example in
the [Getting started](#getting-started) section can also be specified as below.

```ruby
# app/controllers/echo_controller.rb

class EchoController < Jsapi::Controller::Base
  api_info title: 'Echo', version: '1'

  api_rescue_from Jsapi::Controller::ParametersInvalid, with: 400

  api_operation path: '/echo' do
    parameter 'call', type: 'string', existence: true
    response 200, type: 'object' do
      property 'echo', type: 'string'
    end
    response 400, type: 'object' do
      property 'status', type: 'integer'
      property 'message', type: 'string'
    end
  end
end
```

Furthermore, API definitions can be specified within an `api_definitions` block as below.

```ruby
# app/controllers/echo_controller.rb

class EchoController < Jsapi::Controller::Base
  api_definitions do
    info title: 'Echo', version: '1'

    rescue_from Jsapi::Controller::ParametersInvalid, with: 400

    operation path: '/echo' do
      parameter 'call', type: 'string', existence: true
      response 200, type: 'object'  do
        property 'echo', type: 'string'
      end
      response 400, type: 'object' do
        property 'status', type: 'integer'
        property 'message', type: 'string'
      end
    end
  end
end
```

All keywords except `ref`, `schema` and `type` can also be specified as a directive,
for example:

```ruby
parameter 'call', type: 'string' do
  existence true
end
```

### Defining API components

The following directives are provided to define API components:

- [api_operation](#defining-operations) - Defines an operation bound to an API endpoint.
- [api_parameter](#defining-and-referring-reusable-parameters) - Defines a reusable parameter.
- [api_request_body](#defining-and-referring-reusable-request-bodies) - Defines a reusable
  request body.
- [api_response](#defining-and-refering-reusable-responses) - Defines a reusable response.
- [api_schema](#defining-and-referring-reusable-schemas) - Defines a reusable schema.

The names and types of API components can be strings or symbols.

#### Defining operations

An operation can be defined as below.

```ruby
api_operation 'foo' do
  parameter 'bar', type: 'string'
  response do
    property 'foo', type: 'string'
  end
end
```

The operation name can be omitted, if the controller handles one operation only.

`api_operations` takes the following keywords:

- `:deprecated` - Specifies whether or not the operation is deprecated.
- `:description` - The description of the operation.
- `:method` - The HTTP verb of the operation.
- `:model` - See [API models](#api-models).
- `:path` - The relative path of the operation.
- `:summary` - The short summary of the operation.
- `:tags` - One or more tags used to group operations in an OpenAPI document.

##### Parameters

A (top-level) parameter of an operation can be defined as below.

```ruby
api_operation 'foo' do
  parameter 'bar', type: 'string'
end
```

A nested parameter can be defined as below.

```ruby
api_operation 'foo' do
  parameter 'bar' do
    property 'foo', type: 'string'
  end
end
```

`parameter` takes the following keywords:

- `:conversion` - See [The conversion keyword](#the-conversion-keyword).
- `:default` - The default value.
- `:deprecated` - Specifies whether or not the parameter is deprecated.
- `:description` - The description of the parameter.
- `:example` - See [Defining examples](#defining-examples).
- `:existence` - See [The existence keyword](#the-existence-keyword).
- `:in` - The location of the parameter. Possible values are `"header"`,
   `"path"` and "query"`. The default value is `"query"`.
- `:items` - See [The items keyword](#the-items-keyword).
- `:format` - See [The format keyword](#the-format-keyword).
- `:model` - See [API models](#api-models).
- `:schema` - See [Reusable schemas](#reusable-schemas)
- `:title` - The title of the parameter.
- `:type` - See [The type keyword](#the-type-keyword).

Additionally, all of the [validation keywords](#validation-keywords) can be specified to
validate parameter values.

##### Request bodies

The request body of an operation can be defined as below.

```ruby
api_operation 'foo' do
  request_body do
    property 'bar', type: 'string'
  end
end
```

`request_body` takes the following keywords:

- `:content_type`- The content type, `"application/json"` by default.
- `:default` - The default value.
- `:deprecated` - Specifies whether or not the request body is deprecated.
- `:description` - The description of the request body.
- `:example` - See [Defining examples](#defining-examples).
- `:existence` - See [The existence keyword](#the-existence-keyword).
- `:schema` - See [Reusable schemas](#reusable-schemas)
- `:title` - The title of the request body.

##### Responses

A response of an operation can be defined as below.

```ruby
api_operation 'foo' do
  response 200 do
    property 'bar', type: 'string'
  end
end
```

`response` takes the following keywords:

- `:additional_properties` -
  See [The additional_properties keyword](#the-additional-properties-keyword).
- `:content_type`- The content type, `"application/json"` by default.
- `:deprecated` - Specifies whether or not the response is deprecated.
- `:description` - The description of the response.
- `:example` - See [Defining examples](#defining-examples).
- `:existence` - See [The existence keyword](#the-existence-keyword).
- `:headers` - Specifies the HTTP headers of the response.
- `:items` - See [The items keyword](#the-items-keyword).
- `:format` - See [The format keyword](#the-format-keyword).
- `:links` - The linked operations.
- `:locale` - The locale to be used when rendering a response.
- `:schema` - See [Reusable schemas](#reusable-schemas)
- `:title` - The title of the response.
- `:type` - See [The type keyword](#the-type-keyword).

##### Properties

A property can be defined as below.

```ruby
property 'foo', type: 'string'
```

```ruby
property 'foo' do
  property 'bar', type: 'string'
end
```

`property` takes the following keywords:

- `:additional_properties` -
  See [The additional_properties keyword](#the-additional-properties-keyword).
- `:conversion` - See [The conversion keyword](#the-conversion-keyword).
- `:default` - The default value.
- `:deprecated` - Specifies whether or not the property is deprecated.
- `:description` -  The description of the property.
- `:example` - See [Defining examples](#defining-examples).
- `:existence` - See [The existence keyword](#the-existence-keyword).
- `:items` - See [The items keyword](#the-items-keyword).
- `:format` - See [The format keyword](#the-format-keyword).
- `:model` - See [API models](#api-models).
- `:read_only` - Specifies whether or not the property is read only.
- `:schema` - See [Reusable schemas](#reusable-schemas)
- `:source` - See [The source keyword](#the-source-keyword)
- `:title` - The title of the property.
- `:type` - See [The type keyword](#the-type-keyword).
- `:write_only` - Specifies whether or not the property is write only.

Additionally, all of the [validation keyword](#validation-keywords) can be specified to
validate nested parameter values.

#### Defining and referring reusable schemas

The `api_schema` method defines a schema that can be associated with parameters,
request bodies, responses and properties.

```ruby
api_schema 'Foo' do
  property 'bar', type: 'string'
end

api_operation do
  parameter 'foo', schema: 'Foo'
end
```

The properties of a schema can be included in another schema by calling the `all_of` method.

```ruby
api_schema 'Bar' do
  all_of 'Foo'
end
```

Polymorphism:

```ruby
api_schema 'Base' do
  discriminator property_name: 'type' do
    mapping 'foo', 'Foo'
    mapping 'bar', 'Bar'
  end
  property 'type', type: 'string', existence: true
end

schema 'Foo' do
  all_of 'Base'
  property 'foo', type: 'string'
end

schema 'Bar' do
  all_of 'Base'
  property 'bar', type: 'string'
end
```

#### Defining and referring reusable parameters

The `api_parameter` method defines a parameter that can be used in multiple operations.

```ruby
api_parameter 'foo', type: 'string'

api_operation do
  parameter 'foo'
end
```

#### Defining and referring reusable request bodies

The `api_request_body` method defines a request body that ca be used in multiple operations.

```ruby
api_request_body 'foo' do
  property 'bar', type: 'string'
end

api_operation do
  request_body 'foo'
end
```

#### Defining and referring reusable responses

The `api_response` method defines a response that can be used in multiple operations.

```ruby
api_response 'foo' do
  property 'bar', type: 'string'
end

api_operation do
  response 'foo'
end
```

#### The `:type` keyword

The `:type` keyword specifies the type of a parameter, request body, response,
parameter or schema. The supported types correspond to JSON Schema:

- `array`
- `boolean`
- `integer`
- `number`
- `object`
- `string`

The default type is `object`.

#### The `:existence` keyword

The `:existence` keyword combines the presence concepts of Rails and JSON Schema
by four levels of existence:

- `:present` or `true` -  The parameter or property value must not be empty.
- `:allow_empty` - The parameter or property value can be empty, for example `''`.
- `:allow_nil` or `allow_null` - The parameter or property value can be `nil`.
- `:allow_omitted` or `false` - The parameter or property can be omitted.

The default level of existence is `false`.

Note that `existence: :present` slightly differs from Rails `present?` as it treats `false`
to be present.

#### The `:conversion` keyword

The `conversion` keyword can be used to convert integers, numbers and strings by a method or
a `Proc`, for example:

```ruby
# Conversion by method
parameter 'foo', type: 'string', conversion: :upcase

# Conversion by proc
parameter 'foo', type: 'string', conversion: ->(value) { value.upcase }
```

#### The `:additional_properties` keyword

The `:additional_properties` keyword defines the schema of properties that are not
explicity specified, for example:

```ruby
  schema 'foo', additional_properties: { type: 'string', source: :bar }
```

The default source is `:additional_properties`.

#### The `:source` keyword

The `:source` keyword specifies the sequence of methods or the `Proc` to be called to read
property values. A source can be a string, a symbol, an array or a `Proc`, for example:

```ruby
property 'foo', source: 'bar.foo'
```

```ruby
property 'foo', source: %i[bar foo]
```

```ruby
property 'foo', source: ->(bar) { bar.foo }
```

#### The `:items` keyword

The `:items` keyword specifies the kind of items that can be contained in an
array, for example:

```ruby
parameter 'foo', type: 'array', items: { type: 'string' }
```

```ruby
parameter 'foo', type: 'array' do
  items do
    property 'bar', type: 'string'
  end
end
```

#### The `:format` keyword

The `:format` keyword specifies the format of a string. If the format is `"date"`,
`"date-time"` or `"duration"`, parameter and property values are implicitly
casted as below.

- `"date"` - `Date`
- `"date-time"` - `DateTime`
- `"duration"` - `ActiveSupport::Duration`

All other formats are only used for documentation.

#### Validation keywords

The following keywords can be specified to validate parameter values. The
validation keywords correspond to JSON Schema validations.

- `:enum` - The valid values.
- `:max_items` - The maximum length of an array.
- `:max_length` - The maximum length of a string.
- `:maximum` - The maximum value of an integer or a number.
- `:min_items` - The minimum length of an array.
- `:min_length` - The minimum length of a string.
- `:minimum` - The minimum value of an integer or a number.
- `:multiple_of` - The value an integer or a number must be a multiple of.
- `:pattern` - The regular expression a string must match.

The minimum and maximum value can be specified as shown below.

```ruby
# Restrict values to positive integers
parameter 'foo', type: 'integer', minimum: 1

# Restrict values to positive numbers
parameter 'bar', type: 'number', minimum: { value: 0, exclusive: true }
```

### Defining rescue handlers

Rescue handlers are used to render error responses when an exception is raised. A rescue
handler can be defined as below.

```ruby
api_rescue_from Jsapi::Controller::ParametersInvalid, with: 400
```

To notice exceptions caught by a rescue handler a callback can be defined as below.

```ruby
api_on_rescue :foo

api_on_rescue do |error|
  # ...
end
```

### Defining general default values

The general default values for a type can be defined as below.

```ruby
api_default 'array', within_requests: [], within_responses: []
```

`api_default` takes the following keywords:

- `:within_requests` - The general default value of parameters when reading requests.
- `:within_responses` - The general default value of properties when producing responses.

### Defining examples

A simple sample value can be specified as below.

```ruby
property 'foo', type: 'string', example: 'bar'
```

Multiple sample values can be specified as below.

```ruby
schema 'Foo', type: 'object' do
  property 'foo', type: 'string'

  example 'foo', value: { 'foo' => 'foo' }
  example 'bar', value: { 'foo' => 'bar' }
end
```

`example` takes the following keywords:

- `description` - The description of the example.
- `external` - Specifies whether `value` is the URI of an external example.
- `summary` - The short summary of the example.
- `value` - The sample value

### Specifying additional information

The following methods are provided to specify additional information:

- [api_base_path](#specifying-the-base-path) - Specifies the base path of the API.
- [api_callback](#specifying-reusable-callbacks) - Specifies a reusable callback.
- [api_example](#specifying-reusable-examples) - Specifies a reusable example.
- [api_external_docs](#specifying-external-documentation) - Specifies the external
  documentation.
- [api_header](#specifying-reusable-headers) - Specifies a reusable header.
- [api_host](#specifying-the-host) - Specifies the host serving the API.
- [api_info](#specifying-general-information) - Specifies general information about the API.
- [api_link](#specifying-reusable-link) - Specifies a reusable link.
- [api_scheme](#specifying-a-uri-scheme) - Specifies a URI scheme supported by the API.
- [api_security_requirement](#specifying-security-requirements) - Specifies a security
  requirement.
- [api_security_scheme](#specifying-security-schemes) - Specifies a security scheme.
- [api_server](#specifying-servers) - Specifies a server providing the API
- [api_tag](#specifying-tags) - Specifies a tag.

#### Specifying general information

```ruby
api_info title: 'Foo', version: '1' do
  contact name: 'bar'
end
```

#### Specifying servers

```ruby
api_server 'https://foo.bar/foo'
```

#### Specifying the host

```ruby
api_host 'foo.bar'
```

#### Specifying the base path

```ruby
api_base_path '/foo'
```

#### Specifying a URI scheme

```ruby
api_scheme 'https'
```

#### Specifying reusable callbacks

```ruby
api_callback 'foo' do
  operation '{$request.query.bar}', path: '/bar'
end
```

#### Specifying reusable headers

```ruby
api_header 'foo', type: 'string'
```

#### Specifying reusable examples

```ruby
api_example 'foo', value: 'bar'
```

#### Specifying reusable links

```ruby
api_link 'foo', operation_id: 'bar'
```

#### Specifying security schemes

```ruby
api_security_scheme 'basic_auth', type: 'http', scheme: 'basic'
```

#### Specifying security requirements

```ruby
api_security_requirement do
  scheme 'basic_auth'
end
```

#### Specifying tags

```ruby
api_tag name: 'foo', description: 'Description of foo'
```

#### Specifying external documentation

```ruby
api_external_docs url: 'https://foo.bar'
```

### Sharing API components

API components can be used in multiple classes by inheritance or inclusion. A controller
class inherits all API components from the parent class, for example:

```ruby
class FooController < Jsapi::Controller::Base
  api_schema 'Foo'
end

class BarController < FooController
  api_response 'Bar', schema: 'Foo'
end
```

In addition, API components from other classes can be included as below.

```ruby
class FooController < Jsapi::Controller::Base
  api_schema 'Foo'
end

class BarController < Jsapi::Controller::Base
  api_include FooController
  api_response 'Bar', schema: 'Foo'
end
```

### Importing definitions

API definitions can also be specified in separate files located in `apps/api_defs`. Directives
within files are specified as in `api_definitions` blocks without prefix `api_`, for example:

```ruby
# app/api_defs/foo.rb

operation 'foo' do
  # ...
end
```

The API definitions specified in a file are automatically imported into a controller if the
file name matches the controller name. For example, `app/api_defs/foo.rb` is automatically
imported into `FooController`. Other files can be imported as below.

```ruby
class FooController < Jsapi::Controller::Base
  api_import 'bar'
end
```

Within a file, other files can be imported as below.

```ruby
# app/api_defs/foo/bar.rb

import 'foo/shared'
```

```ruby
# app/api_defs/foo/bar.rb

import_relative 'shared'
```

The location of API definitions can be changed by an initializer:

```ruby
# config/initializers/jsapi.rb

Jsapi.configuration.api_defs_path = 'app/foo'
```

## API controllers

An API controller class must either inherit from `Jsapi::Controller::Base` or include
`Jsapi::Controller::Methods`.

```ruby
class FooController < Jsapi::Controller::Base
  # ...
end
```

```ruby
class FooController < ActionController::API
  include Jsapi::Controller::Methods
  # ...
end
```

Note that `Jsapi::Controller::Base` inherits from `ActionController::API` and includes
`Jsapi::DSL` as well as `Jsapi::Controller::Methods`.

The `Jsapi::Controller::Methods` module provides the following methods to deal with
API operations:

- [api_params](#the-api_params-method)
- [api_response](#the-api_response-method)
- [api_operation](#the-api_operation-method)
- [api_operation!](#the-api_operation-method-1)
- [api_definitions](#the-api-definitions-method)

### The `api_params` method

`api_params` can be used to read request parameters as an instance of an operation's model
class. The request parameters are casted according the operation's `parameter` and
`request_body` specifications. Parameter names are converted to snake case.

```ruby
params = api_params('foo')
```

The one and only positional argument specifies the name of the API operation. It can be
omitted if the controller handles one API operation only.

Note that each call of `api_params` returns a newly created instance. Thus, the instance
returned by `api_params` must be locally stored when validating request parameters,
for example:

```ruby
if (params = api_params).valid?
  # ...
else
  full_messages = params.errors.full_messages
  # ...
end
```

### The `api_response` method

`api_response` can be used to serialize an object according to one of the API operation's
`response` specifications.

```ruby
render(json: api_response(foo, 'foo', status: 200))
```

The object to be serialized is passed as the first positional argument. The second positional
argument specifies the name of the API operation. It can be omitted if the controller handles
one API operation only. `status` specifies the HTTP status code of the response to be selected.
If `status` is not present, the default response of the API operation is selected.

### The `api_operation` method

`api_operation` performs an API operation by calling the given block. The request parameters
are passed as an instance of the operation's model class to the block.

This method implicitly renders the JSON representation of the object returned by the block.
This can be a hash or an object providing corresponding methods for all properties of the
response.

```ruby
api_operation('foo', status: 200) do |api_params|
  raise BadRequest if api_params.invalid?

  # ...
end
```

The one and only positional argument specifies the name of the API operation. It can be omitted
if the controller handles one API operation only. `status` specifies the HTTP status code of
the response to be selected. If `status` is not present, the default response of the API
operation is selected.

If an exception is raised while performing the block, an error response according to the first
matching rescue handler is rendered and all of the callbacks are called. If no matching rescue
handler could be found, the exception is raised again.

### The `api_operation!` method

Like `api_operation`, except that a `Jsapi::Controller::ParametersInvalid` exception is raised
on invalid request parameters.

```ruby
api_operation!('foo') do |api_params|
  # ...
end
```

The `errors` instance method of `Jsapi::Controller::ParametersInvalid` returns all of the
validation errors encountered.

### The `api_definitions` method

`api_definitions` returns the API definitions of the controller class. In particular,  this
method can be used to create an OpenAPI document.

```ruby
render(json: api_definitions.openapi_document)
```

### Strong parameters

The `api_operation`, `api_operation!` and `api_params` methods take a `:strong` option that
specifies whether or not request parameters that can be mapped are accepted only.

```ruby
api_params('foo', strong: true)
```

The model returned is invalid if there are any request parameters that cannot be mapped to a
parameter or a request body property of the API operation. For each parameter that can't be
mapped an error is added to the model. The pattern of error messages can be customized using
I18n as below.

```yaml
# config/en.yml
en:
  jsapi:
    errors:
      forbidden: "{name} is forbidden"
```

The default pattern is `{name} isn't allowed`.

## API models

By default, the parameters returned by the `params` method of a controller are wrapped by
an instance of `Jsapi::Model::Base`. Parameter names are converted to snake case. This allows
parameter values to be read by Ruby-stylish methods, even if parameter names are represented
in camel case.

Additional model methods can be added by a `model` block, for example:

```ruby
api_schema 'IntegerRange' do
  property 'range_begin', type: 'integer'
  property 'range_end', type: 'integer'

  model do
    def range
      @range ||= (range_begin..range_end)
    end
  end
end
```

To use additional model methods in multiple API components, a subclass of `Jsapi::Model::Base`
can be use as below.

```ruby
class BaseRange < Jsapi::Model::Base
  def range
    @range ||= (range_begin..range_end)
  end
end
```

```ruby
api_schema 'IntegerRange', model: BaseRange do
  property 'range_begin', type: 'integer'
  property 'range_end', type: 'integer'
end

api_schema 'DateRange', model: BaseRange do
  property 'range_begin', type: 'string', format: 'date'
  property 'range_end', type: 'string', format: 'date'
end
```

A model class may also have validations, for example:

```ruby
class BaseRange < Jsapi::Model::Base
  validate :end_greater_than_or_equal_to_begin

  private

  def end_greater_than_or_equal_to_begin
    return if range_begin.blank? || range_end.blank?

    if range_end < range_begin
      errors.add(:range_end, :greater_than_or_equal_to, count: range_begin)
    end
  end
end
```
