# Default Shell
SHELL = /bin/bash

# Default build path
BUILD_PATH = build

# Flags
CXXFLAGS = -g -O3 -fPIC -Wall -Werror -Wsign-compare
LDFLAGS = -g -O3 -Wall -Werror

# SOS source directory
SRC_PATH = src

# SOS test source directory
TEST_SRC_PATH = test

# SOS include paths
INCLUDES = -I$(SRC_PATH)

# Test include paths
TEST_INCLUDES = $(INCLUDES) -I$(TEST_SRC_PATH) -Itest/ext/Catch/single_include

# SOS objects
LIB_SRC = $(SRC_PATH)/sos.cc
LIB_OBJ = $(BUILD_PATH)/sos.o

# SOS tests object
TEST_SRC = $(TEST_SRC_PATH)/test-libsos.cc
TEST_OBJ = $(BUILD_PATH)/test-libsos.o

OBJECTS = $(LIB_OBJ) $(TEST_OBJ)
DEPENDS  = $(OBJECTS:.o=.d)

.PHONY: all
all: libsos.a test-libsos

libsos.a: $(LIB_OBJ)
	$(AR) rcs $(BUILD_PATH)/libsos.a $^

test-libsos: libsos.a $(TEST_OBJ)
	$(CXX) $(TEST_OBJ) $(BUILD_PATH)/libsos.a $(LDFLAGS) -o $(BUILD_PATH)/$@

.PHONY: test
test: test-libsos
	$(BUILD_PATH)/test-libsos

.PHONY: clean
clean:
	$(RM) -r build

$(BUILD_PATH)/%.o: $(SRC_PATH)/%.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -MP -MMD -c $< -o $@

$(BUILD_PATH)/%.o: $(TEST_SRC_PATH)/%.cc
	$(CXX) $(CXXFLAGS) $(TEST_INCLUDES) -MP -MMD -c $< -o $@

$(LIB_OBJ): | $(BUILD_PATH)

$(BUILD_PATH):
	mkdir -p $(BUILD_PATH)

-include $(DEPENDS)
