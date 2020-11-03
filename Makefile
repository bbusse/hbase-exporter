hbase_tmp_path := /tmp/hbase
bindings_path := $(CURDIR)/hbase-protobuf-python

all:
	@echo Generating Python Protobuf bindings from HBase source
	-mkdir $(bindings_path)
	-git clone --depth 1 https://github.com/apache/hbase $(hbase_tmp_path)
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) *.proto
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) client/*.proto
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) server/*.proto
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) server/io/*.proto
	cd $(hbase_tmp_path)/hbase-protocol-shaded/src/main/protobuf; \
	protoc -I=/usr/local/include/ --proto_path=. --python_out=$(bindings_path) server/zookeeper/*.proto


clean:
	rm -rf $(hbase_tmp_path)
	rm -rf $(bindings_path)
