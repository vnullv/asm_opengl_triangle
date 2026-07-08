AS := as
LD := gcc

LIBS := -lGL -lglfw -lGLEW

ASFLAGS :=
LDFLAGS := $(LIBS)

SRC := src/filesystem/read.s \
       src/shaders/program_log_error.s \
       src/shaders/shader_log_error.s \
       src/shaders/loading/shader_loader.s \
       src/shaders/loading/shader_program_loader.s \
       src/main.s

OBJ := $(patsubst src/%, obj/%, $(SRC:.s=.o))

TARGET := asm_opengl_triangle

.PHONY: all clean run

all: $(TARGET)

# Linking stage
$(TARGET): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

obj/%.o: src/%.s
	@mkdir -p $(@D)
	$(AS) $(ASFLAGS) -c $< -o $@

clean:
	rm -rf obj/* $(TARGET)

run: $(TARGET)
	./$(TARGET)
