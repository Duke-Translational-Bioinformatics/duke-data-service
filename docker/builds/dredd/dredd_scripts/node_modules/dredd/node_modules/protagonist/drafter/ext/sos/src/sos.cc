//
//  sos.cc
//  sos
//
//  Created by Pavan Kumar Sunkara on 20/01/15.
//  Copyright (c) 2015 Apiary Inc. All rights reserved.
//

#include "sos.h"

sos::Base::Base(Base::Type type_)
: type(type_)
{
    m_object.reset(::new KeyValues);
    m_array.reset(::new Bases);
}

sos::Base::Base(const sos::Base& rhs)
{
    this->type = rhs.type;
    this->str = rhs.str;
    this->number = rhs.number;
    this->boolean = rhs.boolean;
    this->keys = rhs.keys;

    this->m_object.reset(::new KeyValues(*rhs.m_object.get()));
    this->m_array.reset(::new Bases(*rhs.m_array.get()));
}

sos::Base& sos::Base::operator=(const sos::Base &rhs)
{
    this->type = rhs.type;
    this->str = rhs.str;
    this->number = rhs.number;
    this->boolean = rhs.boolean;
    this->keys = rhs.keys;

    this->m_object.reset(::new KeyValues(*rhs.m_object.get()));
    this->m_array.reset(::new Bases(*rhs.m_array.get()));

    return *this;
}

sos::KeyValues& sos::Base::object()
{
    if (!m_object.get())
        throw std::logic_error("no object key-values set");

    return *m_object;
}

const sos::KeyValues& sos::Base::object() const
{
    if (!m_object.get())
        throw std::logic_error("no object key-values set");

    return *m_object;
}

sos::Bases& sos::Base::array()
{
    if (!m_array.get())
        throw std::logic_error("no array values set");

    return *m_array;
}

const sos::Bases& sos::Base::array() const
{
    if (!m_array.get())
        throw std::logic_error("no array values set");

    return *m_array;
}

sos::Null::Null()
: Base(NullType)
{}

sos::String::String(std::string str_)
{
    type = StringType;
    str = str_;
}

sos::Number::Number(double number_)
{
    type = NumberType;
    number = number_;
}

sos::Boolean::Boolean(bool boolean_)
{
    type = BooleanType;
    boolean = boolean_;
}

sos::Array::Array()
: Base(ArrayType)
{}

void sos::Array::push(const sos::Base& value)
{
    array().push_back(value);
}

void sos::Array::set(const size_t index, const sos::Base& value)
{
    if (array().size() <= index)
        throw std::logic_error("not enough array values set");

    array().at(index) = value;
}

bool sos::Array::empty()
{
    return array().empty();
}

sos::Object::Object()
: Base(ObjectType)
{}

void sos::Object::set(const std::string& key, const sos::Base& value, bool doNotOverride)
{
    sos::Keys::iterator it = std::find(keys.begin(), keys.end(), key);

    if (it != keys.end()) {
        if (doNotOverride) {
            throw std::logic_error("key already present in the object");
        }
        else {
            keys.erase(it);
        }
    }

    keys.push_back(key);
    object().operator[](key) = value;
}

void sos::Object::unset(const std::string &key)
{
    sos::Keys::iterator it = std::find(keys.begin(), keys.end(), key);

    if (it == keys.end()) {
        return;
    }

    sos::KeyValues::iterator valueIt = object().find(key);

    keys.erase(it);
    object().erase(valueIt);
}

bool sos::Object::empty()
{
    return keys.empty();
}

sos::Serialize::Serialize()
{}

void sos::Serialize::process(const Base& root, std::ostream& os, size_t level)
{
    sos::Base::Type type = root.type;

    switch (type) {

        case Base::NullType:
            null(os);
            break;

        case Base::StringType:
            string(root.str, os);
            break;

        case Base::NumberType:
            number(root.number, os);
            break;

        case Base::BooleanType:
            boolean(root.boolean, os);
            break;

        case Base::ArrayType:
            array(root, os, level);
            break;

        case Base::ObjectType:
            object(root, os, level);
            break;

        default:
            break;
    }
}

std::string sos::escapeNewlines(const std::string &input)
{
    size_t pos = 0;
    std::string target(input);

    while ((pos = target.find("\n", pos)) != std::string::npos) {
        target.replace(pos, 1, "\\n");
        pos += 2;
    }

    return target;
}

std::string sos::escapeDoubleQuotes(const std::string &input)
{
    size_t pos = 0;
    std::string target(input);

    while ((pos = target.find("\"", pos)) != std::string::npos) {
        target.replace(pos, 1, "\\\"");
        pos += 2;
    }

    return target;
}

std::string sos::escapeBackslashes(const std::string &input)
{
    size_t pos = 0;
    std::string target(input);

    while ((pos = target.find("\\", pos)) != std::string::npos) {
        target.replace(pos, 1, "\\\\");
        pos += 2;
    }

    return target;
}
