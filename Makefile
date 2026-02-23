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

FFLAGS ?= -assume byterecl -extend-source -O0
WIN_FPFLAGS ?=
WIN_CFLAGS ?= /nologo /c
WIN_LINK_FLAGS ?= /nologo
WIN_BUILD_CFG ?= $(ROOT)/build_ifx/Hspf12.5/x64/Release
WIN_ROOT := $(subst /,\,$(ROOT))
WIN_BUILD_CFG_WIN := $(subst /,\,$(WIN_BUILD_CFG))

define vfproj_sources
$(shell $(PYTHON) $(ROOT)/tools/vfproj_sources.py $(1))
endef

UTIL_SRCS := $(call vfproj_sources,$(VFPROJ)/util/util.vfproj)
ADWDM_SRCS := $(call vfproj_sources,$(VFPROJ)/adwdm/adwdm.vfproj)
WDM_SRCS := $(call vfproj_sources,$(VFPROJ)/wdm/wdm.vfproj)
HSPF125_SRCS := $(call vfproj_sources,$(VFPROJ)/hspf125/hspf125.vfproj)
HEC_SRCS := $(call vfproj_sources,$(VFPROJ)/hec/hec.vfproj)
HSPDSS_SRCS := $(call vfproj_sources,$(VFPROJ)/hspdss/hspdss.vfproj)
DRIVER_SRCS := $(call vfproj_sources,$(DRVPROJ))

UTIL_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/util/,$(notdir $(basename $(UTIL_SRCS)))))
ADWDM_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/adwdm/,$(notdir $(basename $(ADWDM_SRCS)))))
WDM_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/wdm/,$(notdir $(basename $(WDM_SRCS)))))
HSPF125_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/hspf125/,$(notdir $(basename $(HSPF125_SRCS)))))
HEC_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/hec/,$(notdir $(basename $(HEC_SRCS)))))
HSPDSS_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/hspdss/,$(notdir $(basename $(HSPDSS_SRCS)))))
DRIVER_OBJS := $(addsuffix .o,$(addprefix $(OBJ)/driver/,$(notdir $(basename $(DRIVER_SRCS)))))

INCLUDES_util := -I$(SRCROOT)/UTIL
INCLUDES_wdm := -I$(SRCROOT)/WDM -I$(SRCROOT)/UTIL -I$(SRCROOT)/ADWDM
INCLUDES_adwdm := -I$(SRCROOT)/ADWDM -I$(SRCROOT)/UTIL -I$(SRCROOT)/WDM
INCLUDES_hspf125 := -I$(SRCROOT)/HSPF125 -I$(SRCROOT)/UTIL -I$(SRCROOT)/WDM -I$(SRCROOT)/ADWDM -I$(SRCROOT)/HEC -I$(SRCROOT)/HSPDSS
INCLUDES_hec := -I$(SRCROOT)/HEC -I$(SRCROOT)/UTIL
INCLUDES_hspdss := -I$(SRCROOT)/HSPDSS -I$(SRCROOT)/UTIL -I$(SRCROOT)/HSPF125
INCLUDES_driver := -I$(ROOT)/f90apps/Hspf12.5Intel/src -I$(SRCROOT)/HSPF125 -I$(SRCROOT)/UTIL -I$(SRCROOT)/WDM -I$(SRCROOT)/ADWDM -I$(SRCROOT)/HEC -I$(SRCROOT)/HSPDSS

LIBS := $(LIB)/libhspf125.a $(LIB)/libwdm.a $(LIB)/libadwdm.a $(LIB)/libutil.a $(LIB)/libhec.a $(LIB)/libhspdss.a

.PHONY: all selfcontained static-intel windows-release clean
all: selfcontained

selfcontained: $(BIN)/hspf12_5_static_full

static-intel: $(BIN)/hspf12_5_static

# Windows build (requires GNU make + VS Build Tools + Intel oneAPI ifx).
# Keep WIN_FPFLAGS empty to use the current default ifx behavior.
# Optional precision override examples:
#   make windows-release WIN_FPFLAGS=/fp:strict
#   make windows-release WIN_FPFLAGS=/fp:precise
windows-release:
	cmd /c "cd /d \"$(WIN_ROOT)\" && call \"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat\" -arch=x64 -host_arch=x64 >nul 2>&1 && call \"C:\Program Files (x86)\Intel\oneAPI\setvars.bat\" >nul 2>&1 && cd /d \"$(WIN_BUILD_CFG_WIN)\obj\util\" && ifx $(WIN_CFLAGS) $(WIN_FPFLAGS) /I\"$(WIN_ROOT)\lib3.0\SRC\UTIL\" @sources.rsp && lib /nologo /OUT:\"$(WIN_BUILD_CFG_WIN)\lib\util.lib\" @objs.rsp && cd /d \"$(WIN_BUILD_CFG_WIN)\obj\adwdm\" && ifx $(WIN_CFLAGS) $(WIN_FPFLAGS) /I\"$(WIN_ROOT)\lib3.0\SRC\ADWDM\" /I\"$(WIN_ROOT)\lib3.0\SRC\UTIL\" /I\"$(WIN_ROOT)\lib3.0\SRC\WDM\" @sources.rsp && lib /nologo /OUT:\"$(WIN_BUILD_CFG_WIN)\lib\adwdm.lib\" @objs.rsp && cd /d \"$(WIN_BUILD_CFG_WIN)\obj\wdm\" && ifx $(WIN_CFLAGS) $(WIN_FPFLAGS) /I\"$(WIN_ROOT)\lib3.0\SRC\WDM\" /I\"$(WIN_ROOT)\lib3.0\SRC\UTIL\" /I\"$(WIN_ROOT)\lib3.0\SRC\ADWDM\" @sources.rsp && lib /nologo /OUT:\"$(WIN_BUILD_CFG_WIN)\lib\wdm.lib\" @objs.rsp && cd /d \"$(WIN_BUILD_CFG_WIN)\obj\hspf125\" && ifx $(WIN_CFLAGS) $(WIN_FPFLAGS) /I\"$(WIN_ROOT)\lib3.0\SRC\HSPF125\" /I\"$(WIN_ROOT)\lib3.0\SRC\UTIL\" /I\"$(WIN_ROOT)\lib3.0\SRC\WDM\" /I\"$(WIN_ROOT)\lib3.0\SRC\ADWDM\" /I\"$(WIN_ROOT)\lib3.0\SRC\HEC\" /I\"$(WIN_ROOT)\lib3.0\SRC\HSPDSS\" @sources.rsp && lib /nologo /OUT:\"$(WIN_BUILD_CFG_WIN)\lib\hspf125.lib\" @objs.rsp && cd /d \"$(WIN_BUILD_CFG_WIN)\obj\hec\" && ifx $(WIN_CFLAGS) $(WIN_FPFLAGS) /I\"$(WIN_ROOT)\lib3.0\SRC\HEC\" /I\"$(WIN_ROOT)\lib3.0\SRC\UTIL\" @sources.rsp && lib /nologo /OUT:\"$(WIN_BUILD_CFG_WIN)\lib\hec.lib\" @objs.rsp && cd /d \"$(WIN_BUILD_CFG_WIN)\obj\hspdss\" && ifx $(WIN_CFLAGS) $(WIN_FPFLAGS) /I\"$(WIN_ROOT)\lib3.0\SRC\HSPDSS\" /I\"$(WIN_ROOT)\lib3.0\SRC\UTIL\" /I\"$(WIN_ROOT)\lib3.0\SRC\HSPF125\" @sources.rsp && lib /nologo /OUT:\"$(WIN_BUILD_CFG_WIN)\lib\hspdss.lib\" @objs.rsp && cd /d \"$(WIN_BUILD_CFG_WIN)\obj\driver\" && ifx $(WIN_CFLAGS) $(WIN_FPFLAGS) /I\"$(WIN_ROOT)\f90apps\Hspf12.5Intel\src\" /I\"$(WIN_ROOT)\lib3.0\SRC\HSPF125\" /I\"$(WIN_ROOT)\lib3.0\SRC\UTIL\" /I\"$(WIN_ROOT)\lib3.0\SRC\WDM\" /I\"$(WIN_ROOT)\lib3.0\SRC\ADWDM\" /I\"$(WIN_ROOT)\lib3.0\SRC\HEC\" /I\"$(WIN_ROOT)\lib3.0\SRC\HSPDSS\" @sources.rsp && cd /d \"$(WIN_BUILD_CFG_WIN)\bin\" && ifx $(WIN_LINK_FLAGS) /exe:hspf12.5_ifx.exe @link.rsp"

$(BIN)/hspf12_5_static_full: $(DRIVER_OBJS) $(LIBS)
	@mkdir -p $(BIN)
	$(IFX) -static -static-intel -o $@ $(DRIVER_OBJS) -Wl,--start-group $(LIBS) -Wl,--end-group

$(BIN)/hspf12_5_static: $(DRIVER_OBJS) $(LIBS)
	@mkdir -p $(BIN)
	$(IFX) -static-intel -o $@ $(DRIVER_OBJS) -Wl,--start-group $(LIBS) -Wl,--end-group

$(LIB)/libutil.a: $(UTIL_OBJS)
	@mkdir -p $(LIB)
	$(AR) rcs $@ $^

$(LIB)/libadwdm.a: $(ADWDM_OBJS)
	@mkdir -p $(LIB)
	$(AR) rcs $@ $^

$(LIB)/libwdm.a: $(WDM_OBJS)
	@mkdir -p $(LIB)
	$(AR) rcs $@ $^

$(LIB)/libhspf125.a: $(HSPF125_OBJS)
	@mkdir -p $(LIB)
	$(AR) rcs $@ $^

$(LIB)/libhec.a: $(HEC_OBJS)
	@mkdir -p $(LIB)
	$(AR) rcs $@ $^

$(LIB)/libhspdss.a: $(HSPDSS_OBJS)
	@mkdir -p $(LIB)
	$(AR) rcs $@ $^

define make_compile_rule
$(OBJ)/$(1)/$(notdir $(basename $(2))).o: $(2)
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
