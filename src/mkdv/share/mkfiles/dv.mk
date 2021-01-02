#****************************************************************************
#* mkdv.mk
#* common makefile
#****************************************************************************
DV_MK_MKFILES_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

CWD := $(shell pwd)


ifneq (1,$(RULES))

ifeq (,$(MKDV_RUNDIR))
MKDV_RUNDIR=$(CWD)/rundir
endif

ifneq (1,$(MKDV_VERBOSE))
Q=@
endif

ifeq (,$(MKDV_CACHEDIR))
MKDV_CACHEDIR=$(CWD)/cache/$(MKDV_TOOL)
endif

PACKAGES_DIR ?= PACKAGES_DIR_unset
MKDV_TIMEOUT ?= 1ms

MKDV_MKFILES_PATH += $(DV_MK_MKFILES_DIR)
MKDV_INCLUDE_DIR = $(abspath $(DV_MK_MKFILES_DIR)/../include)


# PYBFMS_MODULES += wishbone_bfms
# VLSIM_CLKSPEC += -clkspec clk=10ns

#TOP_MODULE ?= unset

PATH := $(PACKAGES_DIR)/python/bin:$(PATH)
export PATH

MKDV_VL_INCDIRS += $(DV_MK_MKFILES_DIR)/../include

INCFILES = $(foreach dir,$(MKDV_MKFILES_PATH),$(wildcard $(dir)/mkdv_*.mk))
include $(foreach dir,$(MKDV_MKFILES_PATH),$(wildcard $(dir)/mkdv_*.mk))

PYTHONPATH := $(subst $(eval) ,:,$(MKDV_PYTHONPATH))
export PYTHONPATH

else # Rules

# All is the default target run from the command line
all : build run

build :
ifeq (,$(MKDV_MK))
	@echo "Error: MKDV_MK is not set"; exit 1
endif
ifeq (,$(MKDV_TOOL))
	@echo "Error: MKDV_TOOL is not set"; exit 1
endif
ifeq (,$(findstring $(MKDV_TOOL),$(MKDV_AVAILABLE_TOOLS)))
	@echo "Error: MKDV_TOOL $(MKDV_TOOL) is not available ($(MKDV_AVAILABLE_TOOLS))"; exit 1
endif
	mkdir -p $(MKDV_CACHEDIR)
	$(MAKE) -C $(MKDV_CACHEDIR) -f $(MKDV_MK) \
		MKDV_RUNDIR=$(MKDV_RUNDIR) \
		MKDV_CACHEDIR=$(MKDV_CACHEDIR) \
		build-$(MKDV_TOOL) || (echo "FAIL: exit status $$?" > status.txt; exit 1)

run : 
	@echo "INCFILES: $(INCFILES) $(MKDV_AVAILABLE_TOOLS) $(MKDV_AVAILABLE_PLUGINS)"
ifeq (,$(MKDV_MK))
	$(Q)echo "Error: MKDV_MK is not set"; exit 1
endif
ifeq (,$(MKDV_TOOL))
	$(Q)echo "Error: MKDV_TOOL is not set"; exit 1
endif
ifeq (,$(findstring $(MKDV_TOOL),$(MKDV_AVAILABLE_TOOLS)))
	$(Q)echo "Error: MKDV_TOOL $(MKDV_TOOL) is not available ($(MKDV_AVAILABLE_TOOLS))"; exit 1
endif
	$(Q)if test $(CWD) != $(MKDV_RUNDIR); then rm -rf $(MKDV_RUNDIR); fi
	$(Q)mkdir -p $(MKDV_RUNDIR)
	$(Q)$(MAKE) -C $(MKDV_RUNDIR) -f $(MKDV_MK) \
		MKDV_RUNDIR=$(MKDV_RUNDIR) \
		MKDV_CACHEDIR=$(MKDV_CACHEDIR) \
		run-$(MKDV_TOOL) || (echo "FAIL: exit status $$?" > status.txt; exit 1)
ifeq (,$(MKDV_CHECK_TARGET))
	$(Q)echo "PASS: " > $(MKDV_RUNDIR)/status.txt
else
	$(Q)$(MAKE) -C $(MKDV_RUNDIR) -f $(MKDV_MK) \
		MKDV_RUNDIR=$(MKDV_RUNDIR) \
		MKDV_CACHEDIR=$(MKDV_CACHEDIR) $(MKDV_CHECK_TARGET)
endif
		
ifneq (,$(MKDV_TESTS))
else
endif	

clean-all : $(foreach tool,$(DV_TOOLS),clean-$(tool))

clean : 
	rm -rf rundir cache

help : help-$(TOOL)

help-all : 
	@echo "dv-mk help."
	@echo "Available tools: $(DV_TOOLS)"

include $(foreach dir,$(MKDV_MKFILES_PATH),$(wildcard $(dir)/mkdv_*.mk))

endif
