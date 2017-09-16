#!/bin/bash

cd "${0%/*}"

DOCKER0_SUBNET=`ip -o -f inet addr show | awk '/scope global docker0/ {print $4}'`

echo "Building container..."

mkdir -p container

(
	cd container

	if [[ ! -e Dockerfile ]]; then
		echo "Dockerfile nonexistent - writing..."

			cat >Dockerfile <<- EOF
				FROM ceph/demo

				COPY ["preentry.sh", "/preentry.sh"]

				CMD ["/preentry.sh"]
			EOF
	fi

	if [[ ! -e preentry.sh ]]; then
		echo "Preentry shim nonexistent - writing..."

			cat >preentry.sh <<- EOF
				#!/bin/bash

				if [[ -e /etc/ceph ]]; then 
					echo "/etc/ceph exists - removing contents..."

					ls -l /etc/ceph
					rm -rf /etc/ceph/*
				fi

				echo "Starting Ceph..."

				/entrypoint.sh
			EOF

		chmod +x preentry.sh
	fi
)

DOCKER_CONTAINER=`docker build container | awk '/Successfully built/ { print $3 }'`

echo "Container built as ${DOCKER_CONTAINER}."

if [[ -e .tmp_tc_name && ! -z $(cat .tmp_tc_name) ]]; then
	echo "Previous docker container appears to still be running; stopping..."

	if [[ -e .tmp_tc_name ]]; then
		echo "Killing docker container: $(docker kill $(cat .tmp_tc_name))"
	fi

	echo "Stopped."
fi

# We store the running docker container's ID into the temporary file `.tmp_tc_name`
# so that we can remember it through subshells and in case something goes wrong
# and the docker container isn't stopped (i.e. Ctrl-C during running tests.)
# DOCKER_CMD=""
# DOCKER_CMD+="docker run -d --rm --net=host -v $(pwd)/ceph:/etc/ceph "
# DOCKER_CMD+="-e CEPH_PUBLIC_NETWORK=${DOCKER0_SUBNET} "
# DOCKER_CMD+="-e MON_IP=127.0.0.1 "
# DOCKER_CMD+="--entrypoint=/preentry.sh ${DOCKER_CONTAINER}"

docker run -d --rm --net=host -v $(pwd)/ceph:/etc/ceph -e CEPH_PUBLIC_NETWORK=$DOCKER0_SUBNET -e MON_IP=127.0.0.1 --entrypoint=/preentry.sh $DOCKER_CONTAINER > .tmp_tc_name

echo "Started Ceph demo container: $(cat .tmp_tc_name)"
echo "Waiting for Ceph demo container to be ready for tests..."

./do_until_success.sh "docker logs $(cat .tmp_tc_name) | grep -q '/entrypoint.sh: SUCCESS'" 2> /dev/null

echo "Attempting to fix permissions on ceph/ceph/client.admin.keyring from inside the container..."

# The devil's permissions for a total hack
if docker exec $(cat .tmp_tc_name) chmod 666 /etc/ceph/ceph.client.admin.keyring ; then
	echo "Success."

	exit 0
else
	echo "Failed to access container!"
	echo "The command run was: "
	echo ""
	echo "docker run -d --rm --net=host -v $(pwd)/ceph:/etc/ceph -e CEPH_PUBLIC_NETWORK=${DOCKER0_SUBNET} -e MON_IP=127.0.0.1 --entrypoint=/preentry.sh ${DOCKER_CONTAINER}"
	echo ""
	echo "Retrying verbosely (no -d for detach)..."
	echo ""

	docker run --rm --net=host -v $(pwd)/ceph:/etc/ceph -e CEPH_PUBLIC_NETWORK=$DOCKER0_SUBNET -e MON_IP=127.0.0.1 --entrypoint=/preentry.sh $DOCKER_CONTAINER

	exit 1
fi
