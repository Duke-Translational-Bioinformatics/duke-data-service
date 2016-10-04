//
//  main.cpp
//  test-libsos
//
//  Created by Pavan Kumar Sunkara on 1/21/15.
//  Copyright (c) 2015 Apiary Inc. All rights reserved.
//

#define CATCH_CONFIG_MAIN /// < Let catch generate the main()

#include "catch.hpp"
#include "sosJSON.h"
#include "sosYAML.h"
#include "test.h"

TEST_CASE("Object when empty", "[sos]")
{
    sos::Object root;

    REQUIRE(root.empty());
}

TEST_CASE("Object when not empty", "[sos]")
{
    sos::Object root;
    root.set("user", sos::String("pksunkara"));

    REQUIRE(!root.empty());
}

TEST_CASE("Array when empty", "[sos]")
{
    sos::Array root;

    REQUIRE(root.empty());
}

TEST_CASE("Array when not empty", "[sos]")
{
    sos::Array root;
    root.push(sos::String("pksunkara"));

    REQUIRE(!root.empty());
}

TEST_CASE("Override key in object by default", "[sos]")
{
	sos::Object root;
	root.set("user", sos::String("pksunkara"));
	root.set("user", sos::String("pavan"));

	REQUIRE(root.keys.size() == 1);
	REQUIRE(root.keys.at(0) == "user");
	REQUIRE(root.object().operator[]("user").str == "pavan");
}

TEST_CASE("Unset key in object", "[sos]")
{
    sos::Object root;
    root.set("user", sos::String("pksunkara"));

    REQUIRE(root.keys.size() == 1);
    REQUIRE(root.keys.at(0) == "user");
    REQUIRE(root.object().operator[]("user").str == "pksunkara");

    root.unset("user");
    root.unset("ignore");

    REQUIRE(root.keys.empty());
}

TEST_CASE("Serailize JSON", "[sos][json]")
{
    std::stringstream output;
    std::string expected = \
    "{\n"\
    "  \"username\": \"pksunkara\",\n"\
    "  \"age\": 25,\n"\
    "  \"height\": 1.75,\n"\
    "  \"interests\": [\n"\
    "    \"cricket\",\n"\
    "    [\n"\
    "      \"algorithms\",\n"\
    "      \"programming\"\n"\
    "    ]\n"\
    "  ],\n"\
    "  \"contact\": {\n"\
    "    \"facebook\": true,\n"\
    "    \"linkedin\": false,\n"\
    "    \"dribble\": null,\n"\
    "    \"twitter\": [],\n"\
    "    \"reddit\": {},\n"\
    "    \"github\": {\n"\
    "      \"username\": \"pksunkara\",\n"\
    "      \"orgs\": [\n"\
    "        {\n"\
    "          \"id\": \"apiaryio\",\n"\
    "          \"members\": 20\n"\
    "        },\n"\
    "        {\n"\
    "          \"id\": \"flatiron\",\n"\
    "          \"members\": 10\n"\
    "        }\n"\
    "      ]\n"\
    "    }\n"\
    "  },\n"\
    "  \"json\": \"{\\n    \\\"text\\\": \\\"foo \\\\\\\"bar\\\\\\\" baz\\\\n\\\"\\n}\\n\"\n"\
    "}";

    sos::SerializeJSON serializer;
    sos::Object root;

    build(root);
    serializer.process(root, output);

    REQUIRE(output.str() == expected);
}

TEST_CASE("Serializing JSON numbers use fixed notation", "[sos][json]")
{
    std::stringstream output;
    std::string expected = \
    "{\n"\
    "  \"number\": 1234567890\n"\
    "}";

    sos::Object root;
    sos::SerializeJSON serializer;
    root.set("number", sos::Number(1234567890));

    serializer.process(root, output);

    REQUIRE(output.str() == expected);
}

TEST_CASE("Serialize YAML", "[sos][yaml]")
{
    std::stringstream output;
    std::string expected = \
    "username: \"pksunkara\"\n"\
    "age: 25\n"\
    "height: 1.75\n"\
    "interests:\n"\
    "  - \"cricket\"\n"\
    "  -\n"\
    "    - \"algorithms\"\n"\
    "    - \"programming\"\n"\
    "contact:\n"\
    "  facebook: true\n"\
    "  linkedin: false\n"\
    "  dribble: null\n"\
    "  twitter: []\n"\
    "  reddit: {}\n"\
    "  github:\n"\
    "    username: \"pksunkara\"\n"\
    "    orgs:\n"\
    "      -\n"\
    "        id: \"apiaryio\"\n"\
    "        members: 20\n"\
    "      -\n"\
    "        id: \"flatiron\"\n"\
    "        members: 10\n"\
    "json: \"{\\n    \\\"text\\\": \\\"foo \\\\\\\"bar\\\\\\\" baz\\\\n\\\"\\n}\\n\"";

    sos::SerializeYAML serializer;
    sos::Object root;

    build(root);
    serializer.process(root, output);

    REQUIRE(output.str() == expected);
}
