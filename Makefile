include platform.mk

LUA_CLIB_PATH ?= 3rd/skynet/luaclib

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS)

LUA_INC ?= 3rd/skynet/3rd/lua

LUA_CLIB = lkcp

all : \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(LUA_CLIB_PATH)/lkcp.so : lib-src/lkcp.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@	

clean :
	rm -f $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

cleanall : clean
	cd 3rd/skynet && $(MAKE) cleanall

