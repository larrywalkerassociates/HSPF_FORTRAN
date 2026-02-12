ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PYTHON ?= python3
IFX ?= ifx
AR ?= ar

BUILD ?= $(ROOT)/build_ifx_byterecl_wdopux_hspfext
OBJ := $(BUILD)/obj
LIB := $(BUILD)/lib
BIN := $(BUILD)/bin

SRCROOT := $(ROOT)/lib3.0/SRC
VFPROJ := $(ROOT)/lib3.0/IntelLibs
DRVPROJ := $(ROOT)/f90apps/Hspf12.5Intel/Hspf12.5Intel.vfproj
HASS_ENT_SRC := $(ROOT)/f90apps/WdmEnt/src/WdmEnt.f90

FFLAGS ?= -assume byterecl -extend-source -O0

define vfproj_sources
$(shell $(PYTHON) $(ROOT)/tools/vfproj_sources.py $(1))
endef

UTIL_SRCS := $(call vfproj_sources,$(VFPROJ)/util/util.vfproj)
ADWDM_SRCS := $(call vfproj_sources,$(VFPROJ)/adwdm/adwdm.vfproj)
ADWDM_SRCS := $(filter-out %/WDOPVX.FOR,$(ADWDM_SRCS)) $(SRCROOT)/ADWDM/WDOPUX.FOR
WDM_SRCS := $(call vfproj_sources,$(VFPROJ)/wdm/wdm.vfproj)
HSPF125_SRCS := $(call vfproj_sources,$(VFPROJ)/hspf125/hspf125.vfproj)
HEC_SRCS := $(call vfproj_sources,$(VFPROJ)/hec/hec.vfproj)
HSPDSS_SRCS := $(call vfproj_sources,$(VFPROJ)/hspdss/hspdss.vfproj)
DRIVER_SRCS := $(call vfproj_sources,$(DRVPROJ)) $(HASS_ENT_SRC)

UTIL_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/util/,$(notdir $(basename $(UTIL_SRCS)))))
ADWDM_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/adwdm/,$(notdir $(basename $(ADWDM_SRCS)))))
WDM_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/wdm/,$(notdir $(basename $(WDM_SRCS)))))
HSPF125_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/hspf125/,$(notdir $(basename $(HSPF125_SRCS)))))
HEC_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/hec/,$(notdir $(basename $(HEC_SRCS)))))
HSPDSS_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/hspdss/,$(notdir $(basename $(HSPDSS_SRCS)))))
DRIVER_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/driver/,$(notdir $(basename $(DRIVER_SRCS)))))

INC_DIRS := $(SRCROOT)/ADWDM $(SRCROOT)/WDM $(SRCROOT)/UTIL $(SRCROOT)/HSPF125 $(SRCROOT)/HEC $(SRCROOT)/HSPDSS

INCLUDES_util := -I$(SRCROOT)/UTIL
INCLUDES_wdm := -I$(SRCROOT)/WDM -I$(SRCROOT)/UTIL
INCLUDES_adwdm := -I$(SRCROOT)/ADWDM -I$(SRCROOT)/UTIL -I$(SRCROOT)/WDM
INCLUDES_hspf125 := -I$(SRCROOT)/HSPF125 -I$(SRCROOT)/UTIL -I$(SRCROOT)/WDM -I$(SRCROOT)/ADWDM -I$(SRCROOT)/HEC -I$(SRCROOT)/HSPDSS
INCLUDES_hec := -I$(SRCROOT)/HEC -I$(SRCROOT)/UTIL
INCLUDES_hspdss := -I$(SRCROOT)/HSPDSS -I$(SRCROOT)/UTIL
INCLUDES_driver := -I$(ROOT)/f90apps/Hspf12.5Intel/src -I$(SRCROOT)/HSPF125 -I$(SRCROOT)/UTIL -I$(SRCROOT)/WDM -I$(SRCROOT)/ADWDM -I$(SRCROOT)/HEC -I$(SRCROOT)/HSPDSS

LIBS := $(LIB)/libhspf125.a $(LIB)/libwdm.a $(LIB)/libadwdm.a $(LIB)/libutil.a $(LIB)/libhec.a $(LIB)/libhspdss.a

.PHONY: all selfcontained static-intel clean prep
all: selfcontained

prep:
	@for d in $(INC_DIRS); do \
		for f in $$d/*.INC; do \
			[ -e "$$f" ] || continue; \
			lc=$$(basename "$$f" | tr 'A-Z' 'a-z'); \
			ln -sf "$$(basename "$$f")" "$$d/$$lc"; \
		done; \
	done

selfcontained: $(BIN)/hspf12_5_static_full

static-intel: $(BIN)/hspf12_5_static

$(BIN)/hspf12_5_static_full: $(DRIVER_OBJS) $(LIBS)
	@mkdir -p $(BIN)
	$(IFX) -static -static-intel -o $@ $(DRIVER_OBJS) -Wl,--start-group $(LIBS) -Wl,--end-group

$(BIN)/hspf12_5_static: $(DRIVER_OBJS) $(LIBS)
	@mkdir -p $(BIN)
	$(IFX) -static-intel -o $@ $(DRIVER_OBJS) -Wl,--start-group $(LIBS) -Wl,--end-group

$(LIB)/libutil.a: $(UTIL_OBJS)
	@mkdir -p $(LIB)
	rm -f $@
	$(AR) rcs $@ $^

$(LIB)/libadwdm.a: $(ADWDM_OBJS)
	@mkdir -p $(LIB)
	rm -f $@
	$(AR) rcs $@ $^

$(LIB)/libwdm.a: $(WDM_OBJS)
	@mkdir -p $(LIB)
	rm -f $@
	$(AR) rcs $@ $^

$(LIB)/libhspf125.a: $(HSPF125_OBJS)
	@mkdir -p $(LIB)
	rm -f $@
	$(AR) rcs $@ $^

$(LIB)/libhec.a: $(HEC_OBJS)
	@mkdir -p $(LIB)
	rm -f $@
	$(AR) rcs $@ $^

$(LIB)/libhspdss.a: $(HSPDSS_OBJS)
	@mkdir -p $(LIB)
	rm -f $@
	$(AR) rcs $@ $^

define make_compile_rule
$(OBJ)/$(1)/$(notdir $(basename $(2))).o: $(2) | prep
	@mkdir -p $(OBJ)/$(1)
	$(IFX) $(FFLAGS) $(INCLUDES_$(1)) -c $$< -o $$@
endef

$(foreach src,$(UTIL_SRCS),$(eval $(call make_compile_rule,util,$(src))))
$(foreach src,$(ADWDM_SRCS),$(eval $(call make_compile_rule,adwdm,$(src))))
$(foreach src,$(WDM_SRCS),$(eval $(call make_compile_rule,wdm,$(src))))
$(foreach src,$(HSPF125_SRCS),$(eval $(call make_compile_rule,hspf125,$(src))))
$(foreach src,$(HEC_SRCS),$(eval $(call make_compile_rule,hec,$(src))))
$(foreach src,$(HSPDSS_SRCS),$(eval $(call make_compile_rule,hspdss,$(src))))
$(foreach src,$(DRIVER_SRCS),$(eval $(call make_compile_rule,driver,$(src))))

clean:
	rm -rf $(OBJ) $(LIB) $(BIN)/hspf12_5_static $(BIN)/hspf12_5_static_full
