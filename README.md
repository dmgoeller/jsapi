# Jsapi

Easily build OpenAPI compliant APIs with Rails.

## Why Jsapi?

Without Jsapi, complex API applications typically use in-memory models to read requests and
serializers to write responses. When using OpenAPI for documentation purposes, this is done
separatly.

Jsapi brings all this together. The models to read requests, serialization of objects and
optional OpenAPI documentation base on the same API definition. This significantly reduces
the workload and ensures that the OpenAPI documentation is consistent with the server-side
implementation of the API.

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

When calling `GET /echo?call=Hello`, a response with HTTP status code 200 and the following
body is produced:

```json
{
  "echo": "Hello, again"
}
```

When the required `call` parameter is missing or the value of `call` is empty, `api_operation!`
raises a `Jsapi::Controller::ParametersInvalid` error. To rescue such exceptions, add an
`rescue_from` directive to `app/api_defs/echo.rb`:

```ruby
# app/api_defs/echo.rb

rescue_from Jsapi::Controller::ParametersInvalid, with: 400
```

Then a response with HTTP status code 400 and the following body is produced:

```json
{
  "status": 400,
  "message": "'call' can't be blank."
}
```

To produce an OpenAPI document describing the API, add another route, an `info` directive and
a controller action matching the route, for example:

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

The sources and OpenAPI documents of this example are [here](examples/echo).

## Jsapi DSL

Everything needed to build an API is defined by a DSL whose vocabulary bases on OpenAPI and
JSON Schema. This DSL can be used in any controller inheriting from `Jsapi::Controller::Base`
as well as any class extending `Jsapi::DSL`. To avoid naming conflicts with other libraries,
all top-level directives start with `api_`. These are:

- [api_base_path](#specifying-api-locations)
- [api_callback](#callbacks)
- [api_default](#specifying-general-default-values)
- api_definitions
- [api_example](#specifying-examples)
- [api_external_docs](#specifying-external-docs)
- [api_header](#headers)
- [api_host](#specifying-api-locations)
- [api_import](#importing-api-definitions)
- [api_include](#sharing-api-definitions)
- [api_info](#specifying-metadata)
- [api_link](#links)
- [api_on_rescue](#specifying-rescue-handlers-and-callbacks)
- [api_operation](#specifying-operations)
- [api_parameter](#specifying-parameters)
- [api_request_body](#specifying-request-bodies)
- [api_rescue_from](#specifying-rescue-handlers-and-callbacks)
- [api_response](#specifying-responses)
- [api_schema](#specifying-schemas)
- [api_scheme](#specifying-api-locations)
- [api_security_requirement](#specifying-security-schemes-and-requirements)
- [api_security_scheme](#specifying-security-schemes-and-requirements)
- [api_server](#specifying-api-locations)
- [api_tag](#specifying-tags)

When using top-level directives, the example in [Getting started](#getting-started) looks like:

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

All keywords except `:ref`, `:schema` and `:type` may also be specified by nested directives,
for example:

```ruby
parameter 'call', type: 'string' do
  existence true
end
```

Names and types can be specified as strings or symbols. Therefore,

```ruby
parameter 'call', type: 'string'
```

is equivalent to

```ruby
parameter :call, type: :string
```

### Specifying operations

An operation is defined by an `api_operation` directive, for example:

```ruby
api_operation 'foo' do
  parameter 'bar', type: 'string'
  response type: 'object' do
    property 'foo', type: 'string'
  end
end
```

The one and only positional argument specifies the name of the operation. It can be omitted if
the controller handles one operation only. The `api_operation` directive takes the following
keywords:

- `:callbacks` - See [Callbacks].
- `:deprecated` - Specifies whether or not the operation is deprecated.
- `:description` - The description of the operation.
- `:external_docs` - See [Specifying external docs].
- `:method` - The HTTP verb of the operation, `"GET"` by default.
- `:model` - See [API models](#api-models).
- `:openapi_extensions` - See [Specifying OpenAPI extensions].
- `:parameters` - See [Specifying parameters].
- `:path` - The relative path of the operation.
- `:request_body` - See [Specifying request bodies].
- `:responses` - See [Specifying responses].
- `:schemes` - The transfer protocols supported by the operation.
- `:security_requirements` - See [Specifying security schemes and requirements].
- `:servers` - See [Specifying API locations].
- `:summary` - The short summary of the operation.
- `:tags` - The tags to group operations in an OpenAPI document.

All keywords except `:model`, `:parameters`, `:request_body` and `:responses` are only used to
describe the operation in an OpenAPI document. The relative path of an operation is derived
from the controller name, unless it is explictly specified by the `:path` keyword.

#### Callbacks

[Callbacks]: #callbacks

The callbacks that may be initiated by an operation can be described by nested `callback`
directives, for example:

```ruby
api_operation do
  callback 'foo' do
    operation '{$request.query.bar}', path: '/bar'
  end
end
```

The one and only positional argument specifies the mandatory name of the callback. The nested
`operation` directives maps expressions to operations.

If a callback is associated with multiple operations, it can be specified once by an
`api_callback` directive, for example:

```ruby
api_callback 'foo' do
  operation '{$request.query.bar}', path: '/bar'
end
```

A callback specified by an `api_callback` directive can be referred as below.

```ruby
api_operation do
  callback ref: 'foo'
end
```

```ruby
api_operation do
  callback 'foo'
end
```

### Specifying parameters

[Specifying parameters]: #specifying-parameters

A parameter of an operation is defined by a nested `parameter` directive, for example:

```ruby
api_operation do
  parameter 'foo', type: 'string'
end
```

The one and only positional argument specifies the mandatory parameter name. The `parameter`
directive takes all keywords described in [Specifying schemas] to define the schema of a
parameter. Additionally, the following keywords may be specified:

- `:example`, `:examples` - See [Specifying examples].
- `:in` - The location of the parameter. Possible locations are `"header"`, `"path"` and
  `"query"`. The default location is `"query"`.
- `:openapi_extensions` - See [Specifying OpenAPI extensions].
- `:ref` - Refers a reusable parameter.

The `:example`, `examples` and `:openapi_extensions` keywords are only used to describe a
parameter in an OpenAPI document.

#### Reusable parameters

If a parameter is provided by multiple operations, it can be defined once by an `api_parameter`
directive, for example:

```ruby
api_parameter 'request_id', type: 'string'
```

The one and only positional argument specifies the mandatory name of the reusable parameter.

A reusable parameter can be referred as below.

```ruby
api_operation do
  parameter ref: 'request_id'
end
```

```ruby
api_operation do
  parameter 'request_id'
end
```

### Specifying request bodies

[Specifying request bodies]: #specifying-request-bodies

The optional request body of an operation is defined by a nested `request_body` directive,
for example:

```ruby
api_operation do
  request_body type: 'object' do
    property 'foo', type: 'string'
  end
end
```

The `request_body` directive takes all keywords described in [Specifying schemas] to define the
schema of the request body. Additionally, the following keywords may be specified:

- `:content_type` - The content type a request body, `"application/json"` by default.
- `:example`, `:examples` - See [Specifying examples].
- `:openapi_extensions` - See [Specifying OpenAPI extensions].
- `:ref` - Refers a reusable request body.

The `:example`, `:examples` and `:openapi_extensions` keywords are only used to describe the
request body in an OpenAPI document.

#### Reusable request bodies

If multiple operations have the same request body, this request body can be defined once by
an `api_request_body` directive, for example:

```ruby
api_request_body 'foo', type: 'object' do
  property 'bar', type: 'string'
end
```

The one and only positional argument specifies the mandatory name of the reusable request body.

A reusable request body can be referred as below.

```ruby
api_operation do
  request_body ref: 'foo'
end
```

```ruby
api_operation do
  request_body 'foo'
end
```

### Specifying responses

[Specifying responses]: #specifying-responses

A response that may be produced by an operation is defined by a nested `response` directive,
for example:

```ruby
api_operation do
  response 200 do
    property 'foo', type: 'string'
  end
end
```

The optional positional argument specifies the response status. The default response status is
`"default"`. The `response` directive takes all keywords described in [Specifying schemas] to
define the schema of the response. Additionally, the following keywords may be specified:

- `:content_type`- The content type of the response, `"application/json"` by default.
- `:example`, `:examples` - See [Specifying examples].
- `:headers` - See [Headers].
- `:links` - See [Links].
- `:locale` - The locale to be used when rendering a response.
- `:openapi_extensions` - See [Specifying OpenAPI extensions].
- `:ref` - Refers a reusable response.

The `:locale` keyword allows to produce responses in different languages depending on status
code.  This can especially be used to return error responses in English regardless of the
language of regular responses.

The `:example`, `:examples`, `:headers`, `:links` and `:openapi_extensions` keywords are only
used to describe a response in an OpenAPI document.

#### Reusable responses

If a response may be produced by multiple operations, it can be defined once by an
`api_response` directive, for example:

```ruby
api_response 'error', type: 'object' do
  property 'status', type: 'integer'
  property 'detail', type: 'string'
end
```

The one and only positional argument specifies the mandatory name of the reusable response.

A reusable response can be referred as below.

```ruby
api_operation do
  response 400, ref: 'error'
end
```

```ruby
api_operation do
  response 400, 'error'
end
```

#### Headers

[Headers]: #headers

The HTTP headers a response can have can be described by nested `header` directives,
for example:

```ruby
response do
  header 'foo', type: 'string'
end
```

If a header belongs to multiple responses, it can be specified once by an `api_header`
directive, for example:

```ruby
api_header 'foo', type: 'string'
```

The one and only positional argument specifies the mandatory name of the header. The `header`
directive takes all keywords described in [Specifying schemas] to define the schema of the
header.


A header specified by an `api_header` directive can be referred as below.

```ruby
response do
  header ref: 'foo'
end
```

```ruby
response do
  header 'foo'
end
```

#### Links

[Links]: #links

The operations that may follow after a response can be described by `link` directives, for
example:

```ruby
response do
  link 'foo', operation_id: 'bar'
end
```

The one and only positional argument specifies the mandatory name of the link. The `link`
directive take the following keywords:

- `:description` - The description of the link.
- `:operation_id` - The ID of the operation to be linked.
- `:parameters` - The parameters to be passed.
- `:request_body` - The request body to be passed.
- `:server` - The server providing the operation.

If an operation is linked to multiple responses, the link can be specified once by an `api_link`
directive, for example:

```ruby
api_link 'foo', operation_id: 'bar'
```

A link specified by a `api_link` directive can be referred as below.

```ruby
response do
  link ref: 'foo'
end
```

```ruby
response do
  link 'foo'
end
```

### Specifying properties

[Specifying properties]: #specifying-properties

A property of a parameter, request body or response is defined by a nested `property` directive,
for example:

```ruby
api_operation do
  parameter 'foo', type: 'object' do
    property 'bar', type: 'string'
  end
end
```

The one and only positional argument specifies the mandatory property name. The `property`
directive takes all keywords described in [Specifying schemas] to define the schema of a
property. Additionally, the following keywords may be specified:

- `:read_only` - Specifies whether or not the property is read only.
- `:source` - The sequence of methods or `Proc` to be called to read property values.
- `:write_only` - Specifies whether or not the property is write only.

The source can be a string, a symbol, an array or a `Proc`, for example:

```ruby
property 'foo', source: 'bar.foo'
```

```ruby
property 'foo', source: %i[bar foo]
```

```ruby
property 'foo', source: ->(bar) { bar.foo }
```

### Specifying schemas

[Specifying schemas]: #specifying-schemas

The following keywords are provided to define the schema of a parameter, request body, response
or property.

- `:additional_properties` - See [Additional properties].
- `:conversion` - See [The :conversion keyword].
- `:default` - The default value.
- `:deprecated` - Specifies whether or not it is deprecated.
- `:description` -  The description of the parameter, request body, response or property.
- `:enum` - The valid values.
- `:example`, `:examples` - One or more sample values.
- `:existence` - See [The :existence keyword].
- `:format` - See [The :format keyword].
- `:items` - See [The :items keyword].
- `:max_items` - The maximum length of an array.
- `:max_length` - The maximum length of a string.
- `:maximum` - See [The :maximum keyword].
- `:min_items` - The minimum length of an array.
- `:min_length` - The minimum length of a string.
- `:minimum` - See [The :minimum keyword].
- `:model` - See [API models](#api-models).
- `:multiple_of` - The value an integer or a number must be a multiple of.
- `:openapi_extensions` - See [Specifying OpenAPI extensions].
- `:pattern` - The regular expression a string must match.
- `:properties` - See [Specifying properties].
- `:schema` - See [Reusable schemas].
- `:title` - The title of the parameter, request body, response or property.
- `:type` - The type of a parameter, response or property. Possible values are - `"array"`,
  `"boolean"`,  `"integer"`, `"number"`, `"object"` and `"string"`. The default type is
  `"object"`.

The `:deprecated`, `:description`, `:example`, `:examples`, and `:title` keywords are only used
to describe a schema in an OpenAPI or JSON Schema document. Note that examples of a parameter,
request body and response differ from other schemas because they are compliant to the OpenAPI
specification, whereas in all other cases examples are compliant to the JSON Schema
specification.

#### The `:existence` keyword

[The :existence keyword]: #the-existence-keyword

The `:existence` keyword combines the presence concepts of Rails and JSON Schema by four levels
of existence:

- `:present` or `true` -  The parameter or property value must not be empty.
- `:allow_empty` - The parameter or property value can be empty, for example `''`.
- `:allow_nil` or `allow_null` - The parameter or property value can be `nil`.
- `:allow_omitted` or `false` - The parameter or property can be omitted.

The default level of existence is `false`.

Note that `existence: :present` slightly differs from Rails `present?` as it treats `false`
to be present.

#### The `:conversion` keyword

[The :conversion keyword]: #the-conversion-keyword

The `conversion` keyword specifies a method or `Proc` to convert integers, numbers and strings
when consuming requests or producing responses, for example:

```ruby
# Conversion by method
property 'foo', type: 'string', conversion: :upcase
```

```ruby
# Conversion by proc
property 'foo', type: 'string', conversion: ->(value) { value.upcase }
```

#### The `:items` keyword

[The :items keyword]: #the-items-keyword

The `:items` keyword defines the schema of the items that can be contained in an array,
for example:

```ruby
property 'foo', type: 'array', items: { type: 'string' }
```

```ruby
property 'foo', type: 'array' do
  items type: 'object' do
    property 'bar', type: 'string'
  end
end
```

#### The `:format` keyword

[The :format keyword]: #the-format-keyword

The `:format` keyword specifies the format of a string. If the format is `"date"`, `"date-time"`
or `"duration"`, parameter and property values are implicitly casted as below.

- `"date"` - values are casted to `Date`.
- `"date-time"` - values are casted to `DateTime`.
- `"duration"` - values are casted to `ActiveSupport::Duration`.

All other formats are only used to describe the format of a string.

#### The `:maximum` keyword

[The :maximum keyword]: #the-maximum-keyword

The `:maximum` keyword specifies the maximum value an integer or a number can be, for example:

```ruby
# Allow negative integers only
parameter 'foo', type: 'integer', maximum: -1
```

```ruby
# Allow negative numbers only
parameter 'bar', type: 'number', maximum: { value: 0, exclusive: true }
```

#### The `:minimum` keyword

[The :minimum keyword]: #the-minimum-keyword

The `:minimum` keyword specifies the minimum value an integer or a number can be, for example:

```ruby
# Allow positive integers only
parameter 'foo', type: 'integer', minimum: 1
```

```ruby
# Allow positive numbers only
parameter 'bar', type: 'number', minimum: { value: 0, exclusive: true }
```

#### Additional properties

[Additional properties]: #additional-properties

The schema of properties that are not explictly specified is defined by an
`additional_properties` directive, for example:

```ruby
schema 'foo' do
  additional_properties type: 'string', source: :bar
end
```

The `:source` keyword specifies the sequence of methods or `Proc` to be called to read
additional properties. The default source is `:additional_properties`.

#### Reusable schemas

[Reusable schemas]: #reusable-schemas

If a schema is used multiple times, it can be defined once by an `api_schema` directive,
for example:

```ruby
api_schema 'Foo', type: 'object' do
  property 'id', type: 'integer', read_only: true
  property 'bar', type: 'string'
end
```

The one and only positional argument of the `api_schema` directive specifies the mandatory
name of the reusable schema.

A schema defined by `api_schema` can be referred as below.

```ruby
api_operation 'create_foo', method: 'post' do
  request_body schema: 'Foo'
  response schema: 'Foo'
end
```

#### Composition

All properties of another schema can be included by the `all_of` directive, for example:

```ruby
api_schema 'Foo', type: 'object' do
  all_of 'Base'
end
```

The `all_of` directive corresponds to the `allOf` JSON Schema keyword. Note that there are no
equivalent directives for the `anyOf` and `oneOf` keywords.

#### Polymorphism

```ruby
api_schema 'Base', type: 'object' do
  discriminator property_name: 'type' do
    mapping 'foo', 'Foo'
    mapping 'bar', 'Bar'
  end
  property 'type', type: 'string', existence: true
end

api_schema 'Foo', type: 'object' do
  all_of 'Base'
  property 'foo', type: 'string'
end

api_schema 'Bar', type: 'object' do
  all_of 'Base'
  property 'bar', type: 'string'
end
```

### Specifying metadata

Metadata about an API is specified by an `api_info` directive, for example:

```ruby
api_info title: 'Foo', version: '1'
```

The `api_info` directive takes the following keywords:

- `:contact` - See [Contact].
- `:description` - The description of the API.
- `:license` - See [License].
- `:summary` - The short summary of the API.
- `:terms_of_service` - The URL pointing to the terms of service.
- `:title` - The mandatory title of the API.
- `:version` - The mandatory version of the API.

#### Contact

[Contact]: #contact

The contact information are described by a nested `contact` directive, for example:

```ruby
api_info do
  contact email: 'bar@foo.com'
end
```

The `contact` directive takes the following keywords:

- `:email` - The email address of the contact.
- `:name` - The name of the contact.
- `:url` - The URL of the contact.

#### Licence

[License]: #licence

The license of an API is described by a nested `license` directive, for example:

```ruby
api_info do
  license name: 'MIT License', identifier: 'MIT'
end
```

The `license` directive takes the following keywords:

- `:identifier` - The [SPDX](https://spdx.org/licenses/) identifier of the license.
- `:name` - The name of the license.
- `:url` - The URL of the license.

Note that `:identifier` and `:url` are mutually exlusive.

### Specifying API locations

[Specifying API locations]: #specifying-api-locations

The location of an API can either be specified by an `api_server` directive or the `api_scheme`,
`api_host` and `api_base_path` directives, for example:

```ruby
api_server 'https://foo.bar/foo'
```

```ruby
api_scheme 'https'
api_host 'foo.bar'
api_base_path '/foo'
```

The `api_server` directive corresponds to the `Server` object introduced with OpenAPI 3.0. The
positional argument must be an absolute or relative URI.

The `api_scheme`, `api_host` and `api_base_path` directives correspond to the `scheme`, `host`
and `basePath` fields in OpenAPI 2.0.

### Specifying security schemes and requirements

[Specifying security schemes and requirements]: #specifying-security-schemes-and-requirements

A security scheme is described by an `api_scurity_scheme` directive, for example:

```ruby
api_security_scheme 'basic_auth', type: 'http', scheme: 'basic'
```

The one and only positional argument specifies the name of the security scheme. The `:type`
keyword specifies the type of the security scheme. Possible types are:

- `"api_key"`
- `"basic"`
- `"http"`
- `"oauth2"`
- `"open_id_connect"`

Security schemes are linked by `api_security_requirement` or nested `security_requirement`
directives, for example:

```ruby
api_security_requirement 'http_basic' do
  scheme 'basic_auth'
end
```

```ruby
api_operation do
  security_requirement do
    scheme 'basic_auth'
  end
end
```

### Specifying examples

[Specifying examples]: #specifying-examples

A single sample value can be specified by an `example` keyword, for example:

```ruby
property 'foo', type: 'string', example: 'bar'
```

```ruby
property 'foo', type: 'string' do
  example 'bar'
end
```

Named sample values are specified by nested `example`  directives, for example:

```ruby
property 'foo', type: 'string' do
  example 'bar', value: 'value of bar'
end
```

The `example` directive takes the following keywords:

- `description` - The description of the example.
- `external` - Specifies whether `value` is the URI of an external example.
- `summary` - The short summary of the example.
- `value` - The sample value.

#### Reusable examples

If an example matches multiple parameters, request bodies or responses, it can be specified once
by an `api_example` directive, for example:

```ruby
api_example 'foo', value: 'bar'
```

An example specified by a `api_example` directive can be referred as below.

```ruby
property 'foo', type: 'string' do
  example ref: 'foo'
end
```

### Specifying tags

A tag is specified by an `api_tag` directive, for example:

```ruby
api_tag name: 'foo', description: 'Lorem ipsum'
```

The `api_tag` directive takes the following keywords:

- `:external_docs` - See [Specifying external docs].
- `:description` - The description of the tag.
- `:name` - The name of the tag.

### Specifying external docs

[Specifying external docs]: #specifying-external-docs

External documentations are described by `api_external_docs` or nested `external_docs`
directives, for example:

```ruby
api_external_docs url: 'https://foo.bar'
```

```ruby
api_operation do
  external_docs url: 'https://foo.bar'
end
```

Both directives take the following keywords:

- `:description` - The description of the external documentation.
- `:url` - The URI of the external documentation.

### Specifying OpenAPI extensions

[Specifying OpenAPI extensions]: #specifying-openapi-extensions

OpenAPI extensions are specified by nested `openapi_extension` directives, for example:

```ruby
openapi_extension 'foo', 'bar'
```

The first argument specifies the name of the extension. The second argument specifies the
assigned value. Note that the prefix `x-` is added automatically when producing an OpenAPI
document.

### Specifying rescue handlers and callbacks

To rescue exceptions raised while performing an operation, a rescue handler can be defined by
an `api_rescue_from` directive, for example:

```ruby
api_rescue_from Jsapi::Controller::ParametersInvalid, with: 400
```

The one and only positional argument specifies the exception class to be rescued. The `:with`
keyword specifies the status of the error response to be produced.

To notice exceptions caught by a rescue handler, a callback can be added by an `api_on_rescue`
directive, for example:

```ruby
api_on_rescue :foo
```

```ruby
api_on_rescue do |error|
  # ...
end
```

A callback can either be a method name or a block.

### Specifying general default values

The general default values for a type can be defined by an `api_default` directive, for example:

```ruby
api_default 'array', within_requests: [], within_responses: []
```

`api_default` takes the following keywords:

- `:within_requests` - The general default value of parameters when consuming requests.
- `:within_responses` - The general default value of properties when producing responses.

### Importing API definitions

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

### Sharing API definitions

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

This method implicitly renders the JSON representation of the object returned by the block
when the content type is a JSON MIME type. This can be a hash or an object providing
corresponding methods for all properties of the response.

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

### Mass assignment

When creating or updating an ActiveRecord object, attributes can be set using the
`serializable_hash` method provided by `Jsapi::Model::Base`, for example:

```ruby
def create
  api_operation!('create_foo') do |api_params|
    Foo.create! api_params.foo.serializable_hash
  end
end
```

The attributes returned by `serializable_hash` can be filtered by `:only` or `:except`.
An `update` action that only updates the passed attributes only looks like:

```ruby
def update
  api_operation!('update_foo') do |api_params|
    foo = Foo.find api_params.id
    foo.update! api_params.foo.serializable_hash(only: params[:foo].keys)
  end
end
```
