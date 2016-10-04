# Simple C++ Object Serialization (SOS) [![Build Status](https://travis-ci.org/apiaryio/sos.svg?branch=master)](https://travis-ci.org/apiaryio/sos)

A minimal library to serialize C++ objects into JSON-like objects. Build a C++ object using the `sos::*` classes and serialize them into JSON or YAML. You can also provide your own custom serializers.

## Usage

```cpp
#include <iostream>
#include "sos.h"

int main(int argc, char** argv)
{
    // Build an object
    sos::Object root;

    // Build a string and add it to a key in the object
    root.set("username", sos::String("pksunkara"));

    // Build a number and add it to a key in the object
    root.set("age", sos::Number(25));

    // Build a boolean and add it to a key in the object
    root.set("literate", sos::Boolean(true));

    // Build a null and add it to a key in the object
    root.set("email", sos::Null());

    // Build an array
    sos::Array interests;

    // Push items into the array
    interests.push(sos::String("cricket"));
    interests.push(sos::String("programming"));

    // Change an already pushed item in the array
    interests.set(1, sos::String("computers"));

    // Set the array to a key in the object
    root.set("interests", interests);

    // Build the serializer
    sos::SerializeJSON serializer;

    // Output the serialization
    serializer.process(root, std::cout);
}
```

The above snippet will output the following JSON.

```json
{
  "username": "pksunkara",
  "age": 25,
  "literate": true,
  "email": null,
  "interests": [
    "cricket",
    "computers"
  ]
}
```

## Contribute
Fork & Pull Request

## License
MIT License. See the [LICENSE](LICENSE) file.
