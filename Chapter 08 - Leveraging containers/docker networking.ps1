docker network create -d transparent --gateway 10.10.10.254 --subnet 10.10.10.0/24 transparent

docker run --rm -it --network transparent microsoft/nanoserver cmd