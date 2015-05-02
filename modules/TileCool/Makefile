BUILD_DIR=build


CC= g++
CFLAGS= $(WARN) -O2 -c -fPIC -I/usr/include/lua5.2 -fPIC
WARN= -pedantic -Wall
MAKESO= $(CC) -shared -lluabind
#MAKESO= $(CC) -bundle -undefined dynamic_lookup

BIN= TileCool.so
SRC= lib.cpp
OBJ = $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(SRC))

$(BUILD_DIR)/%.o: %.cpp
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(WARN) $< -o $@

all: $(BIN)

$(BIN): $(OBJ)
	$(MAKESO) $(OBJ) -o $(BIN)

clean:
	rm -f $(BIN)
	rm -rf $(BUILD_DIR) 
