#!/bin/bash
usage()
{
    	echo "usage: ./invoke.sh [[OPTIONAL -> [-c | --commit-hash <hash>]] | [OPTIONAL -> [-p | --build-profiles] | [-j | --jvm-arguments]] | [-h | --help]]"
}

funcSrcChanges() {
	retval=$(git diff --name-only $1 HEAD | awk '/src\/main/{print}' | sed -e 's/src\/main\/.*//g' | awk -F/ '{print $(NF-1)}' | sort | uniq | sed -e 's/^/:/' | tr '\n' , | sed -e 's/.$//')
	echo "$retval"
}

funcPOMChanges() {
	retval=$(git diff --name-only $1 HEAD | awk '/pom.xml/{print}' | awk -F/ '{if ($(NF-1)!="pom.xml")print $(NF-1)}' | sort | uniq | sed -e 's/^/:/' | tr '\n' , | sed -e 's/.$//')
	echo "$retval"
}
# if commit has is not provided commit hash is set to last commit ID and 
# build the changes between HEAD and last commit
if [ "$1" != "-c" ]; then
	COMMIT_HASH=$(git rev-parse HEAD^1)
else
	COMMIT_HASH=""
fi
BUILD_PROFILES=""
JVM_ARGUMENTS=""

while [ "$1" != "" ]; do
	case $1 in
		-c | --commit-hash )      shift
								COMMIT_HASH=$1
								;;
        	-p | --build-profiles )      shift
								BUILD_PROFILES=$1
								;;
        	-j | --jvm-arguments )      shift
								JVM_ARGUMENTS=$1
								;;
		-h | --help )           usage
								exit
								;;
		* )                     usage
								exit 1
	esac
	shift
done

echo "--------------------- Smart Build for Connect Version 1.0.0 --------------------"

echo -e "\n\n\n"

if [ "$COMMIT_HASH" != "" ]; then
	a=$( funcSrcChanges $COMMIT_HASH )
	b=$( funcPOMChanges $COMMIT_HASH )
	c=""
	
	if [ "x$a" != "x" ]; then
		c=$a
	fi
	
	if [ "x$b" != "x" ]; then
		if [ "x$c" == "x" ]; then
			c=$b
		else
			c=$c,$b
		fi
	fi
	
		
	### join the strings together and ensure there are no duplicates
	c=$(echo "$c" | tr ',' '\n' | sort | uniq | tr '\n' ',' | sed -e 's/.$//')
     	
	
	
	if [ "x$c" != "x" ]; then
		echo "Building modules [$c]"
                
		if [ "x$BUILD_PROFILES" != "x" ] && [ "x$JVM_ARGUMENTS" != "x" ]; then
			echo "1"
			mvn clean install -pl $c -amd -P $BUILD_PROFILES $JVM_ARGUMENTS
		elif [ "x$BUILD_PROFILES" != "x" ]; then
			echo "2"
			mvn clean install -pl $c -amd -P $BUILD_PROFILES
		elif [ "x$JVM_ARGUMENTS" != "x" ]; then
			echo "3"
			mvn clean install  -pl $c -amd $JVM_ARGUMENTS
		else
			echo "4"
			mvn clean install -pl $c -amd
		fi
        
		STATUS=$?
		if [ $STATUS -eq 0 ]; then
			echo "Deployment Successful"
		else
			echo "Deployment Failed, attempting full build"
			if [ "x$BUILD_PROFILES" != "x" ] && [ "x$JVM_ARGUMENTS" != "x" ]; then
    				echo "4"
    				mvn clean install -P $BUILD_PROFILES $JVM_ARGUMENTS
    			elif [ "x$BUILD_PROFILES" != "x" ]; then
    				echo "4"
    				mvn clean install -P $BUILD_PROFILES
    			elif [ "x$JVM_ARGUMENTS" != "x" ]; then
    				echo "4"
    				mvn clean install $JVM_ARGUMENTS
    			else
    				echo "4"
    				mvn clean install
    			fi
		fi
	else
		echo "Not building as nothing changed"
	fi
else
	usage
fi
