#-------------------------------------------------------------------------------
.SUFFIXES:
#-------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>/devkitpro")
endif

TOPDIR ?= $(CURDIR)

include $(DEVKITPRO)/wut/share/wut_rules

#-------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
# ROMFS is a folder to generate app's romfs
#-------------------------------------------------------------------------------
TARGET		:=	DrawUSDL
BUILD		:=	build
SOURCES		:=	src
INCLUDES	:=	include

export APP_TV_SPLASH  := $(CURDIR)/assets/tv_splash.png
export APP_DRC_SPLASH := $(CURDIR)/assets/drc_splash.png
export APP_ICON       := $(CURDIR)/assets/icon.png

#-------------------------------------------------------------------------------
# options for code generation
#-------------------------------------------------------------------------------
CFLAGS		:=	-g -Wall -O2 -ffunction-sections \
			$(MACHDEP)

CFLAGS		+=	$(INCLUDE) -D__WIIU__ -D__WUT__

CFLAGS		+=  `powerpc-eabi-pkg-config --libs sdl2` -lwut -lm

CXXFLAGS	:=	$(CFLAGS)

ASFLAGS		:=	-g $(MACHDEP)
LDFLAGS		:=	-g $(MACHDEP) $(RPXSPECS) -Wl,-Map,$(notdir $*.map) 

LIBS		:=   `powerpc-eabi-pkg-config --libs sdl2` -lwut -lm

#-------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level
# containing include and lib
#-------------------------------------------------------------------------------
LIBDIRS		:=	$(PORTLIBS) $(WUT_ROOT) 


#-------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#-------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#-------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir))
export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

#-------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#-------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#-------------------------------------------------------------------------------
	export LD	:=	$(CC)
#-------------------------------------------------------------------------------
else
#-------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#-------------------------------------------------------------------------------
endif
#-------------------------------------------------------------------------------

export SRCFILES		:=	$(CPPFILES) $(CFILES) $(SFILES)
export OFILES 		:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE		:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
				$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
				-I$(CURDIR)/$(BUILD)

export LIBPATHS		:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: $(BUILD) clean all

#-------------------------------------------------------------------------------
all: $(BUILD)

$(BUILD): $(SRCFILES)
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#-------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).rpx $(TARGET).elf $(TARGET).wuhb

#-------------------------------------------------------------------------------
else
.PHONY:	all

#-------------------------------------------------------------------------------
# romfs
#-------------------------------------------------------------------------------
include $(PORTLIBS_PATH)/wiiu/share/romfs-wiiu.mk
CFLAGS		+=	$(ROMFS_CFLAGS)
CXXFLAGS	+=	$(ROMFS_CFLAGS)
LIBS		+=	$(ROMFS_LIBS)
OFILES		+=	$(ROMFS_TARGET)
#-------------------------------------------------------------------------------

DEPENDS		:=	$(OFILES:.o=.d)

#-------------------------------------------------------------------------------
# main targets
#-------------------------------------------------------------------------------
all		:	$(OUTPUT).wuhb

$(OUTPUT).wuhb	:	$(OUTPUT).rpx

$(OUTPUT).rpx	:	$(OUTPUT).elf

$(OUTPUT).elf	:	$(OFILES)

-include $(DEPENDS)

#-------------------------------------------------------------------------------
endif
#------------------------------------------------------------------------------- 