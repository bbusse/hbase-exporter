hbase_tmp_path := /tmp/hbase
bindings_path := $(CURDIR)/hbase-protobuf-python

all:
	@echo Generating Python Protobuf bindings from HBase source
	-mkdir $(bindings_path)
	-git clone --depth 1 https://github.com/apache/hbase $(hbase_tmp_path)
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) *
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) client/*
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) server/*
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) server/io/*
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) server/zookeeper/*


clean:
	rm -rf $(hbase_tmp_path)
	rm -rf $(bindings_path)
