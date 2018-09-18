# ---------- Python support using SWIG ----------
.PHONY: help_python # Generate list of Python targets with descriptions.
help_python:
	@echo Use one of the following Python targets:
ifeq ($(SYSTEM),win)
	@$(GREP) "^.PHONY: .* #" $(CURDIR)/makefiles/Makefile.python.mk | $(SED) "s/\.PHONY: \(.*\) # \(.*\)/\1\t\2/"
	@echo off & echo(
else
	@$(GREP) "^.PHONY: .* #" $(CURDIR)/makefiles/Makefile.python.mk | $(SED) "s/\.PHONY: \(.*\) # \(.*\)/\1\t\2/" | expand -t24
	@echo
endif

OR_TOOLS_PYTHONPATH = $(OR_ROOT_FULL)$(CPSEP)$(OR_ROOT_FULL)$Sdependencies$Ssources$Sprotobuf-$(PROTOBUF_TAG)$Spython

# Check for required build tools
ifeq ($(SYSTEM),win)
PYTHON_COMPILER ?= python.exe
ifneq ($(WINDOWS_PATH_TO_PYTHON),)
PYTHON_EXECUTABLE := $(WINDOWS_PATH_TO_PYTHON)\$(PYTHON_COMPILER)
else
PYTHON_EXECUTABLE := $(shell $(WHICH) $(PYTHON_COMPILER) 2>nul)
endif
SET_PYTHONPATH = set PYTHONPATH=$(OR_TOOLS_PYTHONPATH) &&
else # UNIX
PYTHON_COMPILER ?= python$(UNIX_PYTHON_VER)
PYTHON_EXECUTABLE := $(shell which $(PYTHON_COMPILER))
SET_PYTHONPATH = PYTHONPATH=$(OR_TOOLS_PYTHONPATH)
endif

# Detect python3
ifneq ($(PYTHON_EXECUTABLE),)
ifeq ($(shell "$(PYTHON_EXECUTABLE)" -c "from sys import version_info as v; print (str(v[0]))"),3)
PYTHON3 := true
SWIG_PYTHON3_FLAG := -py3 -DPY3
PYTHON3_CFLAGS := -DPY3
endif
endif

# Main target
.PHONY: python # Build Python OR-Tools.
.PHONY: test_python # Test Python OR-Tools using various examples.
ifneq ($(PYTHON_EXECUTABLE),)
python: \
 install_python_modules \
 pyinit \
 pyalgorithms \
 pygraph \
 pycp \
 pylp \
 pysat \
 pyrcpsp

test_python: \
 test_python_tests \
 test_python_samples \
 test_python_examples

BUILT_LANGUAGES +=, Python$(PYTHON_VERSION)
else
python:
	@echo PYTHON_EXECUTABLE = "${PYTHON_EXECUTABLE}"
	$(warning Cannot find '$(PYTHON_COMPILER)' command which is needed for build. Please make sure it is installed and in system path.)

test_python: python
endif

.PHONY: install_python_modules
install_python_modules: dependencies/sources/protobuf-$(PROTOBUF_TAG)/python/google/protobuf/descriptor_pb2.py
dependencies/sources/protobuf-$(PROTOBUF_TAG)/python/google/protobuf/descriptor_pb2.py: \
dependencies/sources/protobuf-$(PROTOBUF_TAG)/python/setup.py
ifeq ($(SYSTEM),win)
	copy dependencies$Sinstall$Sbin$Sprotoc.exe dependencies$Ssources$Sprotobuf-$(PROTOBUF_TAG)$Ssrc
	cd dependencies$Ssources$Sprotobuf-$(PROTOBUF_TAG)$Spython && "$(PYTHON_EXECUTABLE)" setup.py build
endif
ifeq ($(PLATFORM),LINUX)
	cd dependencies$Ssources$Sprotobuf-$(PROTOBUF_TAG)$Spython && \
 LD_LIBRARY_PATH="$(UNIX_PROTOBUF_DIR)/lib64":"$(UNIX_PROTOBUF_DIR)/lib":$(LD_LIBRARY_PATH) \
 PROTOC=$(PROTOC_BINARY) \
 "$(PYTHON_EXECUTABLE)" setup.py build
endif
ifeq ($(PLATFORM),MACOSX)
	cd dependencies$Ssources$Sprotobuf-$(PROTOBUF_TAG)$Spython && \
 DYLD_LIBRARY_PATH="$(UNIX_PROTOBUF_DIR)/lib":$(DYLD_LIBRARY_PATH) \
 PROTOC=$(PROTOC_BINARY) \
 "$(PYTHON_EXECUTABLE)" setup.py build
endif

.PHONY: pyinit
pyinit: $(GEN_DIR)/ortools/__init__.py

$(GEN_DIR)/ortools/__init__.py: | $(GEN_DIR)/ortools
	$(COPY) ortools$S__init__.py $(GEN_PATH)$Sortools$S__init__.py

#######################
##  Python Wrappers  ##
#######################
# pywrapknapsack_solver
PYALGORITHMS_LIBS = $(LIB_DIR)/_pywrapknapsack_solver.$(SWIG_PYTHON_LIB_SUFFIX)
ifeq ($(PLATFORM),MACOSX)
PYALGORITHMS_LDFLAGS = -install_name @rpath/_pywrapknapsack_solver.$(SWIG_PYTHON_LIB_SUFFIX) #
endif
pyalgorithms: $(PYALGORITHMS_LIBS)

$(GEN_DIR)/ortools/algorithms/pywrapknapsack_solver.py: \
 $(SRC_DIR)/ortools/base/base.i \
 $(SRC_DIR)/ortools/util/python/vector.i \
 $(SRC_DIR)/ortools/algorithms/python/knapsack_solver.i \
 $(SRC_DIR)/ortools/algorithms/knapsack_solver.h \
 | $(GEN_DIR)/ortools/algorithms
	$(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -python $(SWIG_PYTHON3_FLAG) \
 -o $(GEN_PATH)$Sortools$Salgorithms$Sknapsack_solver_python_wrap.cc \
 -module pywrapknapsack_solver \
 ortools$Salgorithms$Spython$Sknapsack_solver.i

$(GEN_DIR)/ortools/algorithms/knapsack_solver_python_wrap.cc: \
 $(GEN_DIR)/ortools/algorithms/pywrapknapsack_solver.py

$(OBJ_DIR)/swig/knapsack_solver_python_wrap.$O: \
 $(GEN_DIR)/ortools/algorithms/knapsack_solver_python_wrap.cc \
 $(ALGORITHMS_DEPS) \
 | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) $(PYTHON_INC) $(PYTHON3_CFLAGS) \
 -c $(GEN_PATH)$Sortools$Salgorithms$Sknapsack_solver_python_wrap.cc \
 $(OBJ_OUT)$(OBJ_DIR)$Sswig$Sknapsack_solver_python_wrap.$O

$(PYALGORITHMS_LIBS): $(OBJ_DIR)/swig/knapsack_solver_python_wrap.$O $(OR_TOOLS_LIBS)
	$(DYNAMIC_LD) \
 $(PYALGORITHMS_LDFLAGS) \
 $(LD_OUT)$(LIB_DIR)$S_pywrapknapsack_solver.$(SWIG_PYTHON_LIB_SUFFIX) \
 $(OBJ_DIR)$Sswig$Sknapsack_solver_python_wrap.$O \
 $(OR_TOOLS_LNK) \
 $(SYS_LNK) \
 $(PYTHON_LNK) \
 $(PYTHON_LDFLAGS)
ifeq ($(SYSTEM),win)
	copy $(LIB_DIR)$S_pywrapknapsack_solver.$(SWIG_PYTHON_LIB_SUFFIX) $(GEN_PATH)\\ortools\\algorithms\\_pywrapknapsack_solver.pyd
else
	cp $(PYALGORITHMS_LIBS) $(GEN_PATH)/ortools/algorithms
endif

# pywrapgraph
PYGRAPH_LIBS = $(LIB_DIR)/_pywrapgraph.$(SWIG_PYTHON_LIB_SUFFIX)
ifeq ($(PLATFORM),MACOSX)
PYGRAPH_LDFLAGS = -install_name @rpath/_pywrapgraph.$(SWIG_PYTHON_LIB_SUFFIX) #
endif
pygraph: $(PYGRAPH_LIBS)

$(GEN_DIR)/ortools/graph/pywrapgraph.py: \
 $(SRC_DIR)/ortools/base/base.i \
 $(SRC_DIR)/ortools/util/python/vector.i \
 $(SRC_DIR)/ortools/graph/python/graph.i \
 $(SRC_DIR)/ortools/graph/min_cost_flow.h \
 $(SRC_DIR)/ortools/graph/max_flow.h \
 $(SRC_DIR)/ortools/graph/ebert_graph.h \
 $(SRC_DIR)/ortools/graph/shortestpaths.h \
 | $(GEN_DIR)/ortools/graph
	$(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -python $(SWIG_PYTHON3_FLAG) \
 -o $(GEN_PATH)$Sortools$Sgraph$Sgraph_python_wrap.cc \
 -module pywrapgraph \
 ortools$Sgraph$Spython$Sgraph.i

$(GEN_DIR)/ortools/graph/graph_python_wrap.cc: \
 $(GEN_DIR)/ortools/graph/pywrapgraph.py

$(OBJ_DIR)/swig/graph_python_wrap.$O: \
 $(GEN_DIR)/ortools/graph/graph_python_wrap.cc \
 $(GRAPH_DEPS) \
 | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) $(PYTHON_INC) $(PYTHON3_CFLAGS) \
 -c $(GEN_PATH)/ortools/graph/graph_python_wrap.cc \
 $(OBJ_OUT)$(OBJ_DIR)$Sswig$Sgraph_python_wrap.$O

$(PYGRAPH_LIBS): $(OBJ_DIR)/swig/graph_python_wrap.$O $(OR_TOOLS_LIBS)
	$(DYNAMIC_LD) \
 $(PYGRAPH_LDFLAGS) \
 $(LD_OUT)$(LIB_DIR)$S_pywrapgraph.$(SWIG_PYTHON_LIB_SUFFIX) \
 $(OBJ_DIR)$Sswig$Sgraph_python_wrap.$O \
 $(OR_TOOLS_LNK) \
 $(SYS_LNK) \
 $(PYTHON_LNK) \
 $(PYTHON_LDFLAGS)
ifeq ($(SYSTEM),win)
	copy $(LIB_DIR)$S_pywrapgraph.$(SWIG_PYTHON_LIB_SUFFIX) $(GEN_PATH)\\ortools\\graph\\_pywrapgraph.pyd
else
	cp $(PYGRAPH_LIBS) $(GEN_PATH)/ortools/graph
endif

# pywrapcp
PYCP_LIBS = $(LIB_DIR)/_pywrapcp.$(SWIG_PYTHON_LIB_SUFFIX)
ifeq ($(PLATFORM),MACOSX)
PYCP_LDFLAGS = -install_name @rpath/_pywrapcp.$(SWIG_PYTHON_LIB_SUFFIX) #
endif
pycp: $(PYCP_LIBS)

$(GEN_DIR)/ortools/constraint_solver/search_limit_pb2.py: \
 $(SRC_DIR)/ortools/constraint_solver/search_limit.proto \
 | $(GEN_DIR)/ortools/constraint_solver
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)$Sortools$Sconstraint_solver$Ssearch_limit.proto

$(GEN_DIR)/ortools/constraint_solver/model_pb2.py: \
 $(SRC_DIR)/ortools/constraint_solver/model.proto \
 $(GEN_DIR)/ortools/constraint_solver/search_limit_pb2.py \
 | $(GEN_DIR)/ortools/constraint_solver
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)$Sortools$Sconstraint_solver$Smodel.proto

$(GEN_DIR)/ortools/constraint_solver/assignment_pb2.py: \
 $(SRC_DIR)/ortools/constraint_solver/assignment.proto \
 | $(GEN_DIR)/ortools/constraint_solver
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)$Sortools$Sconstraint_solver$Sassignment.proto

$(GEN_DIR)/ortools/constraint_solver/solver_parameters_pb2.py: \
 $(SRC_DIR)/ortools/constraint_solver/solver_parameters.proto \
 | $(GEN_DIR)/ortools/constraint_solver
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)$Sortools$Sconstraint_solver$Ssolver_parameters.proto

$(GEN_DIR)/ortools/constraint_solver/routing_enums_pb2.py: \
 $(SRC_DIR)/ortools/constraint_solver/routing_enums.proto \
 | $(GEN_DIR)/ortools/constraint_solver
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)$Sortools$Sconstraint_solver$Srouting_enums.proto

$(GEN_DIR)/ortools/constraint_solver/routing_parameters_pb2.py: \
 $(SRC_DIR)/ortools/constraint_solver/routing_parameters.proto \
 $(GEN_DIR)/ortools/constraint_solver/solver_parameters_pb2.py \
 $(GEN_DIR)/ortools/constraint_solver/routing_enums_pb2.py \
 | $(GEN_DIR)/ortools/constraint_solver
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)$Sortools$Sconstraint_solver$Srouting_parameters.proto

$(GEN_DIR)/ortools/constraint_solver/pywrapcp.py: \
 $(SRC_DIR)/ortools/base/base.i \
 $(SRC_DIR)/ortools/util/python/vector.i \
 $(SRC_DIR)/ortools/constraint_solver/python/constraint_solver.i \
 $(SRC_DIR)/ortools/constraint_solver/python/routing.i \
 $(SRC_DIR)/ortools/constraint_solver/constraint_solver.h \
 $(SRC_DIR)/ortools/constraint_solver/constraint_solveri.h \
 $(GEN_DIR)/ortools/constraint_solver/assignment_pb2.py \
 $(GEN_DIR)/ortools/constraint_solver/model_pb2.py \
 $(GEN_DIR)/ortools/constraint_solver/routing_enums_pb2.py \
 $(GEN_DIR)/ortools/constraint_solver/routing_parameters_pb2.py \
 $(GEN_DIR)/ortools/constraint_solver/search_limit_pb2.py \
 $(GEN_DIR)/ortools/constraint_solver/solver_parameters_pb2.py \
 $(GEN_DIR)/ortools/constraint_solver/assignment.pb.h \
 $(GEN_DIR)/ortools/constraint_solver/model.pb.h \
 $(GEN_DIR)/ortools/constraint_solver/search_limit.pb.h \
 $(CP_LIB_OBJS) \
 | $(GEN_DIR)/ortools/constraint_solver
	$(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -python $(SWIG_PYTHON3_FLAG) \
 -o $(GEN_PATH)$Sortools$Sconstraint_solver$Sconstraint_solver_python_wrap.cc \
 -module pywrapcp \
 $(SRC_DIR)/ortools/constraint_solver$Spython$Srouting.i

$(GEN_DIR)/ortools/constraint_solver/constraint_solver_python_wrap.cc: \
 $(GEN_DIR)/ortools/constraint_solver/pywrapcp.py

$(OBJ_DIR)/swig/constraint_solver_python_wrap.$O: \
 $(GEN_DIR)/ortools/constraint_solver/constraint_solver_python_wrap.cc \
 $(CP_DEPS) \
 | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) $(PYTHON_INC) $(PYTHON3_CFLAGS) \
 -c $(GEN_PATH)$Sortools$Sconstraint_solver$Sconstraint_solver_python_wrap.cc \
 $(OBJ_OUT)$(OBJ_DIR)$Sswig$Sconstraint_solver_python_wrap.$O

$(PYCP_LIBS): $(OBJ_DIR)/swig/constraint_solver_python_wrap.$O $(OR_TOOLS_LIBS)
	$(DYNAMIC_LD) \
 $(PYCP_LDFLAGS) \
 $(LD_OUT)$(LIB_DIR)$S_pywrapcp.$(SWIG_PYTHON_LIB_SUFFIX) \
 $(OBJ_DIR)$Sswig$Sconstraint_solver_python_wrap.$O \
 $(OR_TOOLS_LNK) \
 $(SYS_LNK) \
 $(PYTHON_LNK) \
 $(PYTHON_LDFLAGS)
ifeq ($(SYSTEM),win)
	copy $(LIB_DIR)$S_pywrapcp.$(SWIG_PYTHON_LIB_SUFFIX) $(GEN_PATH)\\ortools\\constraint_solver\\_pywrapcp.pyd
else
	cp $(PYCP_LIBS) $(GEN_PATH)/ortools/constraint_solver
endif

# pywraplp
PYLP_LIBS = $(LIB_DIR)/_pywraplp.$(SWIG_PYTHON_LIB_SUFFIX)
ifeq ($(PLATFORM),MACOSX)
PYLP_LDFLAGS = -install_name @rpath/_pywraplp.$(SWIG_PYTHON_LIB_SUFFIX) #
endif
pylp: $(PYLP_LIBS)

$(GEN_DIR)/ortools/util/optional_boolean_pb2.py: \
 $(SRC_DIR)/ortools/util/optional_boolean.proto \
 | $(GEN_DIR)/ortools/util
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)/ortools/util/optional_boolean.proto

$(GEN_DIR)/ortools/linear_solver/linear_solver_pb2.py: \
 $(SRC_DIR)/ortools/linear_solver/linear_solver.proto \
 $(GEN_DIR)/ortools/util/optional_boolean_pb2.py \
 | $(GEN_DIR)/ortools/linear_solver
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)/ortools/linear_solver/linear_solver.proto

$(GEN_DIR)/ortools/linear_solver/pywraplp.py: \
 $(SRC_DIR)/ortools/base/base.i \
 $(SRC_DIR)/ortools/util/python/vector.i \
 $(SRC_DIR)/ortools/linear_solver/python/linear_solver.i \
 $(SRC_DIR)/ortools/linear_solver/linear_solver.h \
 $(GEN_DIR)/ortools/linear_solver/linear_solver.pb.h \
 $(GEN_DIR)/ortools/linear_solver/linear_solver_pb2.py \
 | $(GEN_DIR)/ortools/linear_solver
	$(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -python $(SWIG_PYTHON3_FLAG) \
 -o $(GEN_PATH)$Sortools$Slinear_solver$Slinear_solver_python_wrap.cc \
 -module pywraplp \
 $(SRC_DIR)/ortools/linear_solver$Spython$Slinear_solver.i

$(GEN_DIR)/ortools/linear_solver/linear_solver_python_wrap.cc: \
 $(GEN_DIR)/ortools/linear_solver/pywraplp.py

$(OBJ_DIR)/swig/linear_solver_python_wrap.$O: \
 $(GEN_DIR)/ortools/linear_solver/linear_solver_python_wrap.cc \
 $(LP_DEPS) \
 | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) $(PYTHON_INC) $(PYTHON3_CFLAGS) \
 -c $(GEN_PATH)$Sortools$Slinear_solver$Slinear_solver_python_wrap.cc \
 $(OBJ_OUT)$(OBJ_DIR)$Sswig$Slinear_solver_python_wrap.$O

$(PYLP_LIBS): $(OBJ_DIR)/swig/linear_solver_python_wrap.$O $(OR_TOOLS_LIBS)
	$(DYNAMIC_LD) \
 $(PYLP_LDFLAGS) \
 $(LD_OUT)$(LIB_DIR)$S_pywraplp.$(SWIG_PYTHON_LIB_SUFFIX) \
 $(OBJ_DIR)$Sswig$Slinear_solver_python_wrap.$O \
 $(OR_TOOLS_LNK) \
 $(SYS_LNK) \
 $(PYTHON_LNK) \
 $(PYTHON_LDFLAGS)
ifeq ($(SYSTEM),win)
	copy $(LIB_DIR)$S_pywraplp.$(SWIG_PYTHON_LIB_SUFFIX) $(GEN_PATH)\\ortools\\linear_solver\\_pywraplp.pyd
else
	cp $(PYLP_LIBS) $(GEN_PATH)/ortools/linear_solver
endif

# pywrapsat
PYSAT_LIBS = $(LIB_DIR)/_pywrapsat.$(SWIG_PYTHON_LIB_SUFFIX)
ifeq ($(PLATFORM),MACOSX)
PYSAT_LDFLAGS = -install_name @rpath/_pywrapsat.$(SWIG_PYTHON_LIB_SUFFIX) #
endif
pysat: $(PYSAT_LIBS)

$(GEN_DIR)/ortools/sat/cp_model_pb2.py: \
 $(SRC_DIR)/ortools/sat/cp_model.proto \
 | $(GEN_DIR)/ortools/sat
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)/ortools/sat/cp_model.proto

$(GEN_DIR)/ortools/sat/sat_parameters_pb2.py: \
 $(SRC_DIR)/ortools/sat/sat_parameters.proto \
 | $(GEN_DIR)/ortools/sat
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)/ortools/sat/sat_parameters.proto

$(GEN_DIR)/ortools/sat/pywrapsat.py: \
 $(SRC_DIR)/ortools/base/base.i \
 $(SRC_DIR)/ortools/util/python/vector.i \
 $(SRC_DIR)/ortools/sat/python/sat.i \
 $(GEN_DIR)/ortools/sat/cp_model_pb2.py \
 $(GEN_DIR)/ortools/sat/sat_parameters_pb2.py \
 $(SAT_DEPS) \
 | $(GEN_DIR)/ortools/sat
	$(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -python $(SWIG_PYTHON3_FLAG) \
 -o $(GEN_PATH)$Sortools$Ssat$Ssat_python_wrap.cc \
 -module pywrapsat \
 $(SRC_DIR)/ortools/sat$Spython$Ssat.i

$(GEN_DIR)/ortools/sat/sat_python_wrap.cc: \
 $(GEN_DIR)/ortools/sat/pywrapsat.py

$(OBJ_DIR)/swig/sat_python_wrap.$O: \
 $(GEN_DIR)/ortools/sat/sat_python_wrap.cc \
 $(SAT_DEPS) \
 | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) $(PYTHON_INC) $(PYTHON3_CFLAGS) \
 -c $(GEN_PATH)$Sortools$Ssat$Ssat_python_wrap.cc \
 $(OBJ_OUT)$(OBJ_DIR)$Sswig$Ssat_python_wrap.$O

$(PYSAT_LIBS): $(OBJ_DIR)/swig/sat_python_wrap.$O $(OR_TOOLS_LIBS)
	$(DYNAMIC_LD) \
 $(PYSAT_LDFLAGS) \
 $(LD_OUT)$(LIB_DIR)$S_pywrapsat.$(SWIG_PYTHON_LIB_SUFFIX) \
 $(OBJ_DIR)$Sswig$Ssat_python_wrap.$O \
 $(OR_TOOLS_LNK) \
 $(SYS_LNK) \
 $(PYTHON_LNK) \
 $(PYTHON_LDFLAGS)
ifeq ($(SYSTEM),win)
	copy $(LIB_DIR)$S_pywrapsat.$(SWIG_PYTHON_LIB_SUFFIX) $(GEN_PATH)\\ortools\\sat\\_pywrapsat.pyd
else
	cp $(PYSAT_LIBS) $(GEN_PATH)/ortools/sat
endif

# pywraprcpsp
PYDATA_LIBS = $(LIB_DIR)/_pywraprcpsp.$(SWIG_PYTHON_LIB_SUFFIX)
ifeq ($(PLATFORM),MACOSX)
PYRCPSP_LDFLAGS = -install_name @rpath/_pywraprcpsp.$(SWIG_PYTHON_LIB_SUFFIX) #
endif
pyrcpsp: $(PYDATA_LIBS)

$(GEN_DIR)/ortools/data/rcpsp_pb2.py: \
 $(SRC_DIR)/ortools/data/rcpsp.proto \
 | $(GEN_DIR)/ortools/data
	$(PROTOC) --proto_path=$(INC_DIR) --python_out=$(GEN_PATH) \
 $(SRC_DIR)/ortools/data/rcpsp.proto

$(GEN_DIR)/ortools/data/pywraprcpsp.py: \
 $(SRC_DIR)/ortools/data/rcpsp_parser.h \
 $(SRC_DIR)/ortools/base/base.i \
 $(SRC_DIR)/ortools/data/python/rcpsp.i \
 $(GEN_DIR)/ortools/data/rcpsp_pb2.py \
 $(DATA_DEPS) \
 | $(GEN_DIR)/ortools/data
	$(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -python $(SWIG_PYTHON3_FLAG) \
 -o $(GEN_PATH)$Sortools$Sdata$Srcpsp_python_wrap.cc \
 -module pywraprcpsp \
 $(SRC_DIR)/ortools/data$Spython$Srcpsp.i

$(GEN_DIR)/ortools/data/rcpsp_python_wrap.cc: \
 $(GEN_DIR)/ortools/data/pywraprcpsp.py

$(OBJ_DIR)/swig/rcpsp_python_wrap.$O: \
 $(GEN_DIR)/ortools/data/rcpsp_python_wrap.cc \
 $(DATA_DEPS) \
 | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) $(PYTHON_INC) $(PYTHON3_CFLAGS) \
 -c $(GEN_PATH)$Sortools$Sdata$Srcpsp_python_wrap.cc \
 $(OBJ_OUT)$(OBJ_DIR)$Sswig$Srcpsp_python_wrap.$O

$(PYDATA_LIBS): $(OBJ_DIR)/swig/rcpsp_python_wrap.$O $(OR_TOOLS_LIBS)
	$(DYNAMIC_LD) \
 $(PYRCPSP_LDFLAGS) \
 $(LD_OUT)$(LIB_DIR)$S_pywraprcpsp.$(SWIG_PYTHON_LIB_SUFFIX) \
 $(OBJ_DIR)$Sswig$Srcpsp_python_wrap.$O \
 $(OR_TOOLS_LNK) \
 $(SYS_LNK) \
 $(PYTHON_LNK) \
 $(PYTHON_LDFLAGS)
ifeq ($(SYSTEM),win)
	copy $(LIB_DIR)$S_pywraprcpsp.$(SWIG_PYTHON_LIB_SUFFIX) $(GEN_PATH)\\ortools\\data\\_pywraprcpsp.pyd
else
	cp $(PYDATA_LIBS) $(GEN_PATH)/ortools/data
endif

###############################
##  Python Examples/Samples  ##
###############################
.PHONY: test_python_tests # Run all Python Tests (located in examples/tests)
test_python_tests: python
	$(MAKE) rpy_test_cp_api
	$(MAKE) rpy_test_lp_api

rpy_%: \
 $(TEST_DIR)/%.py \
 $(PYLP_LIBS) \
 $(PYCP_LIBS) \
 $(PYGRAPH_LIBS) \
 $(PYALGORITHMS_LIBS) \
 $(PYSAT_LIBS) \
 $(PYDATA_LIBS)
	$(SET_PYTHONPATH) "$(PYTHON_EXECUTABLE)" $(TEST_PATH)$S$*.py $(ARGS)

.PHONY: test_python_examples # Run all Python Examples (located in examples/python)
test_python_examples: python
	$(MAKE) rpy_3_jugs_mip
	$(MAKE) rpy_3_jugs_regular
	$(MAKE) rpy_alldifferent_except_0
	$(MAKE) rpy_all_interval
	$(MAKE) rpy_alphametic
	$(MAKE) rpy_appointments
	$(MAKE) rpy_a_round_of_golf
	$(MAKE) rpy_assignment6_mip
	$(MAKE) rpy_assignment
	$(MAKE) rpy_assignment_sat
	$(MAKE) rpy_assignment_with_constraints
	$(MAKE) rpy_assignment_with_constraints_sat
	$(MAKE) rpy_bacp
	$(MAKE) rpy_balance_group_sat
	$(MAKE) rpy_blending
	$(MAKE) rpy_broken_weights
	$(MAKE) rpy_bus_schedule
	$(MAKE) rpy_car
	$(MAKE) rpy_check_dependencies
	$(MAKE) rpy_chemical_balance_lp
	$(MAKE) rpy_chemical_balance_sat
	$(MAKE) rpy_circuit
	$(MAKE) rpy_code_samples_sat
	$(MAKE) rpy_coins3
	$(MAKE) rpy_coins_grid_mip
	$(MAKE) rpy_coins_grid ARGS="5 2"
	$(MAKE) rpy_coloring_ip
	$(MAKE) rpy_combinatorial_auction2
	$(MAKE) rpy_contiguity_regular
	$(MAKE) rpy_costas_array
	$(MAKE) rpy_covering_opl
	$(MAKE) rpy_cp_is_fun_sat
	$(MAKE) rpy_crew
	$(MAKE) rpy_crossword2
	$(MAKE) rpy_crypta
	$(MAKE) rpy_crypto
	$(MAKE) rpy_curious_set_of_integers
	$(MAKE) rpy_cvrp
#	$(MAKE) rpy_cvrptw_plot # error: py3 failure, missing numpy.
	$(MAKE) rpy_cvrptw
	$(MAKE) rpy_debruijn_binary
	$(MAKE) rpy_diet1_b
	$(MAKE) rpy_diet1_mip
	$(MAKE) rpy_diet1
	$(MAKE) rpy_discrete_tomography
	$(MAKE) rpy_divisible_by_9_through_1
	$(MAKE) rpy_dudeney
	$(MAKE) rpy_einav_puzzle2
	$(MAKE) rpy_einav_puzzle
	$(MAKE) rpy_eq10
	$(MAKE) rpy_eq20
	$(MAKE) rpy_fill_a_pix
	$(MAKE) rpy_flexible_job_shop_sat
	$(MAKE) rpy_furniture_moving
	$(MAKE) rpy_futoshiki
	$(MAKE) rpy_game_theory_taha
	$(MAKE) rpy_gate_scheduling_sat
	$(MAKE) rpy_golomb8
	$(MAKE) rpy_grocery
	$(MAKE) rpy_hidato ARGS="3 3"
	$(MAKE) rpy_hidato_sat
	$(MAKE) rpy_hidato_table
	$(MAKE) rpy_integer_programming
	$(MAKE) rpy_jobshop_ft06_distance
	$(MAKE) rpy_jobshop_ft06
	$(MAKE) rpy_jobshop_ft06_sat
	$(MAKE) rpy_just_forgotten
	$(MAKE) rpy_kakuro
	$(MAKE) rpy_kenken2
	$(MAKE) rpy_killer_sudoku
	$(MAKE) rpy_knapsack_cp
	$(MAKE) rpy_knapsack_mip
	$(MAKE) rpy_knapsack
	$(MAKE) rpy_labeled_dice
	$(MAKE) rpy_langford
	$(MAKE) rpy_least_diff
	$(MAKE) rpy_least_square
	$(MAKE) rpy_lectures
	$(MAKE) rpy_linear_assignment_api
	$(MAKE) rpy_linear_programming
	$(MAKE) rpy_magic_sequence_distribute
	$(MAKE) rpy_magic_square_and_cards
	$(MAKE) rpy_magic_square_mip
# warning: magic_square take 21s
	$(MAKE) rpy_magic_square
	$(MAKE) rpy_map
	$(MAKE) rpy_marathon2
	$(MAKE) rpy_max_flow_taha
	$(MAKE) rpy_max_flow_winston1
	$(MAKE) rpy_minesweeper
	$(MAKE) rpy_mr_smith
	$(MAKE) rpy_nonogram_default_search
	$(MAKE) rpy_nonogram_regular
	$(MAKE) rpy_nonogram_table2
	$(MAKE) rpy_nonogram_table
#	$(MAKE) rpy_nontransitive_dice # error: too long
	$(MAKE) rpy_nqueens2
	$(MAKE) rpy_nqueens3
	$(MAKE) rpy_nqueens
	$(MAKE) rpy_nqueens_sat
	$(MAKE) rpy_nurse_rostering
	$(MAKE) rpy_nurses_cp
# warning: nurse_sat take 18s
	$(MAKE) rpy_nurses_sat
	$(MAKE) rpy_olympic
	$(MAKE) rpy_organize_day
	$(MAKE) rpy_pandigital_numbers
	$(MAKE) rpy_photo_problem
	$(MAKE) rpy_place_number_puzzle
	$(MAKE) rpy_p_median
	$(MAKE) rpy_post_office_problem2
	$(MAKE) rpy_production
	$(MAKE) rpy_pyflow_example
	$(MAKE) rpy_pyls_api
	$(MAKE) rpy_quasigroup_completion
	$(MAKE) rpy_rabbit_pheasant
	$(MAKE) rpy_rcpsp_sat
	$(MAKE) rpy_regular
	$(MAKE) rpy_regular_table2
	$(MAKE) rpy_regular_table
	$(MAKE) rpy_rogo2
	$(MAKE) rpy_rostering_with_travel
	$(MAKE) rpy_safe_cracking
	$(MAKE) rpy_scheduling_speakers
#	$(MAKE) rpy_school_scheduling_sat # error: too long
	$(MAKE) rpy_secret_santa2
#	$(MAKE) rpy_secret_santa # error: too long
	$(MAKE) rpy_send_more_money_any_base
	$(MAKE) rpy_sendmore
	$(MAKE) rpy_send_most_money
	$(MAKE) rpy_seseman_b
	$(MAKE) rpy_seseman
	$(MAKE) rpy_set_covering2
	$(MAKE) rpy_set_covering3
	$(MAKE) rpy_set_covering4
	$(MAKE) rpy_set_covering_deployment
	$(MAKE) rpy_set_covering
	$(MAKE) rpy_set_covering_skiena
	$(MAKE) rpy_set_partition
	$(MAKE) rpy_sicherman_dice
	$(MAKE) rpy_simple_meeting
	$(MAKE) rpy_ski_assignment
	$(MAKE) rpy_slitherlink
	$(MAKE) rpy_stable_marriage
	$(MAKE) rpy_steel_lns
	$(MAKE) rpy_steel_mill_slab_sat
	$(MAKE) rpy_steel
	$(MAKE) rpy_stigler
	$(MAKE) rpy_strimko2
	$(MAKE) rpy_subset_sum
	$(MAKE) rpy_sudoku
	$(MAKE) rpy_survo_puzzle
	$(MAKE) rpy_toNum
	$(MAKE) rpy_traffic_lights
	$(MAKE) rpy_transit_time
	$(MAKE) rpy_tsp
	$(MAKE) rpy_vendor_scheduling
	$(MAKE) rpy_volsay2
	$(MAKE) rpy_volsay3
	$(MAKE) rpy_volsay
	$(MAKE) rpy_vrpgs
	$(MAKE) rpy_vrp
	$(MAKE) rpy_wedding_optimal_chart
	$(MAKE) rpy_wedding_optimal_chart_sat
	$(MAKE) rpy_who_killed_agatha
#	$(MAKE) rpy_word_square # Not working on window since it rely on /usr/share/dict/words
	$(MAKE) rpy_worker_schedule_sat
	$(MAKE) rpy_xkcd
	$(MAKE) rpy_young_tableaux
	$(MAKE) rpy_zebra

rpy_%: \
 $(PYTHON_EX_DIR)/%.py \
 $(PYLP_LIBS) \
 $(PYCP_LIBS) \
 $(PYGRAPH_LIBS) \
 $(PYALGORITHMS_LIBS) \
 $(PYSAT_LIBS) \
 $(PYDATA_LIBS)
	$(SET_PYTHONPATH) "$(PYTHON_EXECUTABLE)" $(PYTHON_EX_PATH)$S$*.py $(ARGS)

.PHONY: test_python_samples # Run all Python Samples (located in ortools/*/python)
test_python_samples: python
	$(MAKE) rpy_binpacking_problem
	$(MAKE) rpy_bool_or_sample
	$(MAKE) rpy_channeling_sample
	$(MAKE) rpy_code_sample
	$(MAKE) rpy_interval_sample
	$(MAKE) rpy_literal_sample
	$(MAKE) rpy_no_overlap_sample
	$(MAKE) rpy_optional_interval_sample
	$(MAKE) rpy_rabbits_and_pheasants
	$(MAKE) rpy_ranking_sample
	$(MAKE) rpy_reified_sample
	$(MAKE) rpy_simple_solve
	$(MAKE) rpy_solve_all_solutions
	$(MAKE) rpy_solve_with_intermediate_solutions
	$(MAKE) rpy_solve_with_time_limit
	$(MAKE) rpy_stop_after_n_solutions

rpy_%: \
 ortools/sat/samples/%.py \
 $(PYLP_LIBS) \
 $(PYCP_LIBS) \
 $(PYGRAPH_LIBS) \
 $(PYALGORITHMS_LIBS) \
 $(PYSAT_LIBS) \
 $(PYDATA_LIBS)
	$(SET_PYTHONPATH) "$(PYTHON_EXECUTABLE)" ortools$Ssat$Ssamples$S$*.py $(ARGS)

#######################
##  Python Examples  ##
#######################
ifeq ($(EX),) # Those rules will be used if EX variable is not set
.PHONY: rpy
rpy:
	@echo No python file was provided, the $@ target must be used like so: \
 make $@ EX=examples/python/example.py
else # This generic rule will be used if EX variable is set

.PHONY: rpy
rpy: $(EX) \
 $(PYLP_LIBS) $(PYCP_LIBS) $(PYGRAPH_LIBS) $(PYALGORITHMS_LIBS) $(PYSAT_LIBS) $(PYDATA_LIBS)
	@echo running $<
	$(SET_PYTHONPATH) "$(PYTHON_EXECUTABLE)" $(EX) $(ARGS)
endif # ifeq ($(EX),)

################
##  Cleaning  ##
################
.PHONY: clean_python # Clean Python output from previous build.
clean_python:
	-$(DEL) $(GEN_PATH)$Sortools$S__init__.py
	-$(DEL) ortools$S*.pyc
	-$(DELREC) ortools$S__pycache__
	-$(DEL) $(GEN_PATH)$Sortools$Salgorithms$S*.py
	-$(DEL) $(GEN_PATH)$Sortools$Salgorithms$S*.pyc
	-$(DELREC) $(GEN_PATH)$Sortools$Salgorithms$S__pycache__
	-$(DEL) ortools$Salgorithms$S*.pyc
	-$(DELREC) ortools$Salgorithms$S__pycache__
	-$(DEL) $(GEN_PATH)$Sortools$Salgorithms$S*_python_wrap.*
	-$(DEL) $(GEN_PATH)$Sortools$Salgorithms$S_pywrap*
	-$(DEL) $(GEN_PATH)$Sortools$Sgraph$S*.py
	-$(DEL) $(GEN_PATH)$Sortools$Sgraph$S*.pyc
	-$(DELREC) $(GEN_PATH)$Sortools$Sgraph$S__pycache__
	-$(DEL) ortools$Sgraph$S*.pyc
	-$(DELREC) ortools$Sgraph$S__pycache__
	-$(DEL) $(GEN_PATH)$Sortools$Sgraph$S*_python_wrap.*
	-$(DEL) $(GEN_PATH)$Sortools$Sgraph$S_pywrap*
	-$(DEL) $(GEN_PATH)$Sortools$Sconstraint_solver$S*.py
	-$(DEL) $(GEN_PATH)$Sortools$Sconstraint_solver$S*.pyc
	-$(DELREC) $(GEN_PATH)$Sortools$Sconstraint_solver$S__pycache__
	-$(DEL) ortools$Sconstraint_solver$S*.pyc
	-$(DELREC) ortools$Sconstraint_solver$S__pycache__
	-$(DEL) $(GEN_PATH)$Sortools$Sconstraint_solver$S*_python_wrap.*
	-$(DEL) $(GEN_PATH)$Sortools$Sconstraint_solver$S_pywrap*
	-$(DEL) $(GEN_PATH)$Sortools$Slinear_solver$S*.py
	-$(DEL) $(GEN_PATH)$Sortools$Slinear_solver$S*.pyc
	-$(DELREC) $(GEN_PATH)$Sortools$Slinear_solver$S__pycache__
	-$(DEL) ortools$Slinear_solver$S*.pyc
	-$(DELREC) ortools$Slinear_solver$S__pycache__
	-$(DEL) $(GEN_PATH)$Sortools$Slinear_solver$S*_python_wrap.*
	-$(DEL) $(GEN_PATH)$Sortools$Slinear_solver$S_pywrap*
	-$(DEL) $(GEN_PATH)$Sortools$Ssat$S*.py
	-$(DEL) $(GEN_PATH)$Sortools$Ssat$S*.pyc
	-$(DELREC) $(GEN_PATH)$Sortools$Ssat$S__pycache__
	-$(DEL) ortools$Ssat$S*.pyc
	-$(DELREC) ortools$Ssat$S__pycache__
	-$(DEL) ortools$Ssat$Spython$S*.pyc
	-$(DELREC) ortools$Ssat$Spython$S__pycache__
	-$(DEL) $(GEN_PATH)$Sortools$Ssat$S*_python_wrap.*
	-$(DEL) $(GEN_PATH)$Sortools$Ssat$S_pywrap*
	-$(DEL) $(GEN_PATH)$Sortools$Sdata$S*.py
	-$(DEL) $(GEN_PATH)$Sortools$Sdata$S*.pyc
	-$(DELREC) $(GEN_PATH)$Sortools$Sdata$S__pycache__
	-$(DEL) ortools$Sdata$S*.pyc
	-$(DELREC) ortools$Sdata$S__pycache__
	-$(DEL) $(GEN_PATH)$Sortools$Sdata$S*_python_wrap.*
	-$(DEL) $(GEN_PATH)$Sortools$Sdata$S_pywrap*
	-$(DEL) $(GEN_PATH)$Sortools$Sutil$S*.py
	-$(DEL) $(GEN_PATH)$Sortools$Sutil$S*.pyc
	-$(DELREC) $(GEN_PATH)$Sortools$Sutil$S__pycache__
	-$(DEL) ortools$Sutil$S*.pyc
	-$(DELREC) ortools$Sutil$S__pycache__
	-$(DEL) $(GEN_PATH)$Sortools$Sutil$S*_python_wrap.*
	-$(DEL) $(GEN_PATH)$Sortools$Sutil$S_pywrap*
	-$(DEL) $(LIB_DIR)$S_pywrap*.$(SWIG_PYTHON_LIB_SUFFIX)
	-$(DEL) $(OBJ_DIR)$Sswig$S*python_wrap.$O
	-$(DELREC) $(PYPI_ARCHIVE_TEMP_DIR)

#####################
##  Pypi artifact  ##
#####################
PYPI_ARCHIVE_TEMP_DIR = temp-python$(PYTHON_VERSION)

# PEP 513 auditwheel repair overwrite rpath to $ORIGIN/<ortools_root>/.libs
# We need to copy all dynamic libs here
ifneq ($(SYSTEM),win)
PYPI_ARCHIVE_LIBS = $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/.libs
endif

MISSING_PYPI_FILES = \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/README.txt \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/LICENSE-2.0.txt \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/__init__.py \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/algorithms \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/graph \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/constraint_solver \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/linear_solver \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/sat \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/data \
 $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/util \
 $(PYPI_ARCHIVE_LIBS)

$(PYPI_ARCHIVE_TEMP_DIR):
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)

$(PYPI_ARCHIVE_TEMP_DIR)/ortools: | $(PYPI_ARCHIVE_TEMP_DIR)
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools: | $(PYPI_ARCHIVE_TEMP_DIR)/ortools
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/README.txt: tools/README.pypi | $(PYPI_ARCHIVE_TEMP_DIR)/ortools
	$(COPY) tools$SREADME.pypi $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$SREADME.txt

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/LICENSE-2.0.txt: LICENSE-2.0.txt | $(PYPI_ARCHIVE_TEMP_DIR)/ortools
	$(COPY) LICENSE-2.0.txt $(PYPI_ARCHIVE_TEMP_DIR)$Sortools

PYTHON_SETUP_DEPS=
ifeq ($(UNIX_GFLAGS_DIR),$(OR_TOOLS_TOP)/dependencies/install)
  ifeq ($(PLATFORM),MACOSX)
    PYTHON_SETUP_DEPS += , 'libgflags.2.2.$L'
  endif
  ifeq ($(PLATFORM),LINUX)
    PYTHON_SETUP_DEPS += , 'libgflags.$L.2.2'
  endif
endif
ifeq ($(UNIX_GLOG_DIR),$(OR_TOOLS_TOP)/dependencies/install)
  ifeq ($(PLATFORM),MACOSX)
    PYTHON_SETUP_DEPS += , 'libglog.0.3.5.$L'
  endif
  ifeq ($(PLATFORM),LINUX)
    PYTHON_SETUP_DEPS += , 'libglog.$L.0.3.5'
  endif
endif
ifeq ($(UNIX_PROTOBUF_DIR),$(OR_TOOLS_TOP)/dependencies/install)
  ifeq ($(PLATFORM),MACOSX)
    PYTHON_SETUP_DEPS += , 'libprotobuf.3.6.1.$L'
  endif
  ifeq ($(PLATFORM),LINUX)
    PYTHON_SETUP_DEPS += , 'libprotobuf.$L.3.6.1'
  endif
endif
ifeq ($(UNIX_CBC_DIR),$(OR_TOOLS_TOP)/dependencies/install)
  ifeq ($(PLATFORM),MACOSX)
    PYTHON_SETUP_DEPS += , 'libCbcSolver.3.$L'
    PYTHON_SETUP_DEPS += , 'libCbc.3.$L'
    PYTHON_SETUP_DEPS += , 'libOsiCbc.3.$L'
    PYTHON_SETUP_DEPS += , 'libCgl.1.$L'
    PYTHON_SETUP_DEPS += , 'libClpSolver.1.$L'
    PYTHON_SETUP_DEPS += , 'libClp.1.$L'
    PYTHON_SETUP_DEPS += , 'libOsiClp.1.$L'
    PYTHON_SETUP_DEPS += , 'libOsi.1.$L'
    PYTHON_SETUP_DEPS += , 'libCoinUtils.3.$L'
  endif
  ifeq ($(PLATFORM),LINUX)
    PYTHON_SETUP_DEPS += , 'libCbcSolver.$L.3'
    PYTHON_SETUP_DEPS += , 'libCbc.$L.3'
    PYTHON_SETUP_DEPS += , 'libOsiCbc.$L.3'
    PYTHON_SETUP_DEPS += , 'libCgl.$L.1'
    PYTHON_SETUP_DEPS += , 'libClpSolver.$L.1'
    PYTHON_SETUP_DEPS += , 'libClp.$L.1'
    PYTHON_SETUP_DEPS += , 'libOsiClp.$L.1'
    PYTHON_SETUP_DEPS += , 'libOsi.$L.1'
    PYTHON_SETUP_DEPS += , 'libCoinUtils.$L.3'
  endif
endif

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py: tools/setup.py | $(PYPI_ARCHIVE_TEMP_DIR)/ortools
	$(COPY) tools$Ssetup.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools
	$(SED) -i -e 's/ORTOOLS_PYTHON_VERSION/ortools$(PYPI_OS)/' $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Ssetup.py
	$(SED) -i -e 's/VVVV/$(OR_TOOLS_VERSION)/' $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Ssetup.py
	$(SED) -i -e 's/PROTOBUF_TAG/$(PROTOBUF_TAG)/' $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Ssetup.py
ifeq ($(SYSTEM),win)
	$(SED) -i -e 's/\.dll/\.pyd/' $(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py
	$(SED) -i -e '/DELETEWIN/d' $(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py
	$(SED) -i -e 's/DELETEUNIX/          /g' $(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py
	-del $(PYPI_ARCHIVE_TEMP_DIR)\ortools\setup.py-e
else
	$(SED) -i -e 's/\.dll/\.so/' $(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py
	$(SED) -i -e 's/DELETEWIN //g' $(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py
	$(SED) -i -e '/DELETEUNIX/d' $(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py
	$(SED) -i -e 's/DLL/$L/g' $(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py
	$(SED) -i -e "s/DDDD/$(PYTHON_SETUP_DEPS)/g" $(PYPI_ARCHIVE_TEMP_DIR)/ortools/setup.py
endif

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/__init__.py: \
	$(GEN_DIR)/ortools/__init__.py | $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools
	$(COPY) $(GEN_PATH)$Sortools$S__init__.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S__init__.py
ifeq ($(SYSTEM),win)
	echo __version__ = "$(OR_TOOLS_VERSION)" >> \
 $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S__init__.py
else
	echo "__version__ = \"$(OR_TOOLS_VERSION)\"" >> \
 $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S__init__.py
endif

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/algorithms: $(PYALGORITHMS_LIBS) | $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools
	-$(DELREC) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Salgorithms
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Salgorithms
	$(TOUCH) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Salgorithms$S__init__.py
	$(COPY) $(GEN_PATH)$Sortools$Salgorithms$Spywrapknapsack_solver.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Salgorithms
	$(COPY) $(GEN_PATH)$Sortools$Salgorithms$S_pywrapknapsack_solver.* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Salgorithms

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/graph: $(PYGRAPH_LIBS) | $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools
	-$(DELREC) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sgraph
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sgraph
	$(TOUCH) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sgraph$S__init__.py
	$(COPY) $(GEN_PATH)$Sortools$Sgraph$Spywrapgraph.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sgraph
	$(COPY) $(GEN_PATH)$Sortools$Sgraph$S_pywrapgraph.* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sgraph

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/constraint_solver: $(PYCP_LIBS) | $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools
	-$(DELREC) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sconstraint_solver
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sconstraint_solver
	$(TOUCH) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sconstraint_solver$S__init__.py
	$(COPY) $(GEN_PATH)$Sortools$Sconstraint_solver$S*.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sconstraint_solver
	$(COPY) $(GEN_PATH)$Sortools$Sconstraint_solver$S_pywrapcp.* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sconstraint_solver

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/linear_solver: $(PYLP_LIBS) | $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools
	-$(DELREC) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Slinear_solver
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Slinear_solver
	$(TOUCH) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Slinear_solver$S__init__.py
	$(COPY) ortools$Slinear_solver$S*.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Slinear_solver
	$(COPY) $(GEN_PATH)$Sortools$Slinear_solver$S*.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Slinear_solver
	$(COPY) $(GEN_PATH)$Sortools$Slinear_solver$S_pywraplp.* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Slinear_solver

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/sat: $(PYSAT_LIBS) | $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools
	-$(DELREC) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Ssat
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Ssat
	$(TOUCH) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Ssat$S__init__.py
	$(COPY) ortools$Ssat$Sdoc$S*.md $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Ssat
	$(COPY) ortools$Ssat$S*.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Ssat
	$(COPY) $(GEN_PATH)$Sortools$Ssat$S*.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Ssat
	$(COPY) $(GEN_PATH)$Sortools$Ssat$S_pywrapsat.* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Ssat
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Ssat$Spython
	$(COPY) ortools$Ssat$Spython$S*.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Ssat$Spython

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/data: $(PYDATA_LIBS) | $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools
	-$(DELREC) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sdata
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sdata
	$(TOUCH) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sdata$S__init__.py
	$(COPY) $(GEN_PATH)$Sortools$Sdata$S*.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sdata
	$(COPY) $(GEN_PATH)$Sortools$Sdata$S_pywraprcpsp.* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sdata

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/util: | $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools
	-$(DELREC) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sutil
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sutil
	$(TOUCH) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sutil$S__init__.py
	$(COPY) $(GEN_PATH)$Sortools$Sutil$S*.py $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$Sutil

$(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/.libs: | $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools
	-$(DELREC) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs
	$(MKDIR) $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs

.PHONY: pypi_archive # Create Python "ortools" wheel package
pypi_archive: python $(MISSING_PYPI_FILES)
ifneq ($(SYSTEM),win)
	cp $(OR_TOOLS_LIBS) $(PYPI_ARCHIVE_TEMP_DIR)/ortools/ortools/.libs
endif
ifeq ($(UNIX_GFLAGS_DIR),$(OR_TOOLS_TOP)/dependencies/install)
	$(COPYREC) dependencies$Sinstall$Slib$Slibgflags* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs
endif
ifeq ($(UNIX_GLOG_DIR),$(OR_TOOLS_TOP)/dependencies/install)
	$(COPYREC) dependencies$Sinstall$Slib$Slibglog* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs
endif
ifeq ($(UNIX_PROTOBUF_DIR),$(OR_TOOLS_TOP)/dependencies/install)
	$(COPYREC) $(subst /,$S,$(_PROTOBUF_LIB_DIR))$Slibproto* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs
endif
ifeq ($(UNIX_CBC_DIR),$(OR_TOOLS_TOP)/dependencies/install)
	$(COPYREC) dependencies$Sinstall$Slib$SlibCbc* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs
	$(COPYREC) dependencies$Sinstall$Slib$SlibCgl* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs
	$(COPYREC) dependencies$Sinstall$Slib$SlibClp* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs
	$(COPYREC) dependencies$Sinstall$Slib$SlibOsi* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs
	$(COPYREC) dependencies$Sinstall$Slib$SlibCoinUtils* $(PYPI_ARCHIVE_TEMP_DIR)$Sortools$Sortools$S.libs
endif
	cd $(PYPI_ARCHIVE_TEMP_DIR)$Sortools && "$(PYTHON_EXECUTABLE)" setup.py bdist_wheel
ifeq ($(SYSTEM),win)
	cd $(PYPI_ARCHIVE_TEMP_DIR)$Sortools && "$(PYTHON_EXECUTABLE)" setup.py bdist_wininst
endif

.PHONY: install_python # Install Python OR-Tools on the host system
install_python: pypi_archive
	cd "$(PYPI_ARCHIVE_TEMP_DIR)$Sortools" && "$(PYTHON_EXECUTABLE)" setup.py install --user

.PHONY: uninstall_python # Uninstall Python OR-Tools from the host system
uninstall_python:
	"$(PYTHON_EXECUTABLE)" -m pip uninstall ortools

pypi_upload: pypi_archive # Upload Wheel package to Pypi.org
	@echo Uploading Pypi module for "$(PYTHON_EXECUTABLE)".
	cd $(PYPI_ARCHIVE_TEMP_DIR)/ortools && twine upload dist/*

.PHONY: python_examples_archive # Build stand-alone Python examples archive file for redistribution.
python_examples_archive:
	-$(DELREC) temp
	$(MKDIR) temp
	$(MKDIR) temp$Sortools_examples
	$(MKDIR) temp$Sortools_examples$Sexamples
	$(MKDIR) temp$Sortools_examples$Sexamples$Spython
	$(MKDIR) temp$Sortools_examples$Sexamples$Snotebook
	$(MKDIR) temp$Sortools_examples$Sexamples$Sdata
	$(COPY) examples$Spython$S*.py temp$Sortools_examples$Sexamples$Spython
	$(COPY) examples$Snotebook$S*.ipynb temp$Sortools_examples$Sexamples$Snotebook
	$(COPY) examples$Snotebook$S*.md temp$Sortools_examples$Sexamples$Snotebook
	$(COPY) tools$SREADME.examples.python temp$Sortools_examples$SREADME.txt
	$(COPY) LICENSE-2.0.txt temp$Sortools_examples
ifeq ($(SYSTEM),win)
	cd temp\ortools_examples && ..\..\$(TAR) -C ..\.. -c -v --exclude *svn* --exclude *roadef* --exclude *vector_packing* examples\data | ..\..\$(TAR) xvm
	cd temp && ..\$(ZIP) -r ..\or-tools_python_examples_v$(OR_TOOLS_VERSION).zip ortools_examples
else
	cd temp/ortools_examples && tar -C ../.. -c -v --exclude *svn* --exclude *roadef* --exclude *vector_packing* examples/data | tar xvm
	cd temp && tar -c -v -z --no-same-owner -f ../or-tools_python_examples$(PYPI_OS)_v$(OR_TOOLS_VERSION).tar.gz ortools_examples
endif

#############
##  DEBUG  ##
#############
.PHONY: detect_python # Show variables used to build Python OR-Tools.
detect_python:
	@echo Relevant info for the Python build:
ifeq ($(SYSTEM),win)
	@echo WINDOWS_PATH_TO_PYTHON = "$(WINDOWS_PATH_TO_PYTHON)"
else
	@echo UNIX_PYTHON_VER = "$(UNIX_PYTHON_VER)"
endif
	@echo PYTHON_COMPILER = $(PYTHON_COMPILER)
	@echo PYTHON_EXECUTABLE = "$(PYTHON_EXECUTABLE)"
	@echo PYTHON_VERSION = $(PYTHON_VERSION)
	@echo PYTHON3 = $(PYTHON3)
	@echo PYTHON_INC = $(PYTHON_INC)
	@echo PYTHON_LNK = $(PYTHON_LNK)
	@echo PYTHON_LDFLAGS = $(PYTHON_LDFLAGS)
	@echo SWIG_BINARY = $(SWIG_BINARY)
	@echo SWIG_INC = $(SWIG_INC)
	@echo SWIG_PYTHON3_FLAG = $(SWIG_PYTHON3_FLAG)
	@echo SWIG_PYTHON_LIB_SUFFIX = $(SWIG_PYTHON_LIB_SUFFIX)
	@echo SET_PYTHONPATH = "$(SET_PYTHONPATH)"
ifeq ($(SYSTEM),win)
	@echo off & echo(
else
	@echo
endif
