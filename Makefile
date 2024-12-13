# Default target
all: $(TARGET)

# Toolchain settings
CC := $(CC)
AS := $(AS)
SIZE := $(SIZE)

# Directories
SRC :=  # Define SRC as a collection of .c files
INC_DIR :=
TARGET_DIR := $(BUILD_DIR)/$(ARCH)
ARCH := $(ARCH)
include include.mk
$(info  SRC:$(SRC))
$(info  INC_DIR:$(INC_DIR))
$(info  TARGET_DIR:$(TARGET_DIR))
# Source files
C_SRCS := $(SRC)
#ASM_SRCS := $(wildcard $(INC_DIR)/**/*.s)  # Assuming assembly sources are listed similarly
#OBJS := $(patsubst %.c, $(TARGET_DIR)/%.o, $(notdir $(C_SRCS))) $(patsubst $(SRC)/%.s, $(TARGET_DIR)/%.o, $(ASM_SRCS))
OBJS := $(patsubst %.c,$(TARGET_DIR)/%.o,$(SRC)) $(patsubst %.s,$(TARGET_DIR)/%.o,$(ASM_SRCS))
DEPS := $(OBJS:.o=.d)

$(info  C_SRCS:$(C_SRCS))
$(info  OBJS:$(OBJS))
$(info  ASM_SRCS:$(ASM_SRCS))
$(info  DEPS:$(DEPS))
# Compiler and linker flags
CFLAGS := $(CFLAGS) $(foreach dir, $(INC_DIR), -I$(dir))
CFLAGS += -MMD -MP

LDFLAGS := $(LDFLAGS)

# Create build directories
$(TARGET_DIR)/%: 
	@mkdir -p $(@D)
# Build rules
$(TARGET_DIR)/%.o: %.c | $(TARGET_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET_DIR)/%.o: %.s | $(TARGET_DIR)
	$(AS) -c $< -o $@

# Link objects to create target
$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LDFLAGS) -o $(TARGET_DIR)/$(TARGET)
	$(SIZE) $(TARGET_DIR)/$(TARGET)

clean:
	rm -rf $(TARGET_DIR)

-include $(DEPS)
