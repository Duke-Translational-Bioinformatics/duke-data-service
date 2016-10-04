#ifndef SOS_TEST_H
#define SOS_TEST_H

#include "sos.h"

void build(sos::Object& root) {

    root.set("username", sos::String("pksunkara"));
    root.set("age", sos::Number(25));
    root.set("height", sos::Number(1.75));

    sos::Array interests, computer;

    computer.push(sos::String("algorithms"));
    computer.push(sos::String("programming"));

    interests.push(sos::String("cricket"));
    interests.push(computer);

    root.set("interests", interests);

    sos::Object social, github;

    social.set("facebook", sos::Boolean(true));
    social.set("linkedin", sos::Boolean(false));
    social.set("dribble", sos::Null());
    social.set("twitter", sos::Array());
    social.set("reddit", sos::Object());

    github.set("username", sos::String("pksunkara"));

    sos::Array orgs;

    sos::Object apiary = sos::Object();
    sos::Object flatiron = sos::Object();

    apiary.set("id", sos::String("apiaryio"));
    apiary.set("members", sos::Number(20));

    flatiron.set("id", sos::String("flatiron"));
    flatiron.set("members", sos::Number(10));

    orgs.push(apiary);
    orgs.push(flatiron);

    github.set("orgs", orgs);
    social.set("github", github);
    root.set("contact", social);

    root.set("json", sos::String("{\n    \"text\": \"foo \\\"bar\\\" baz\\n\"\n}\n"));
}

#endif
