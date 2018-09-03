CXD

# 1. Check what exists
docker images
docker container ls




# 6. Get Base Container Images
docker pull hello-world
docker pull microsoft/nanoserver
docker pull microsoft/windowsservercore

docker run microsoft/dotnet-samples:dotnetapp-nanoserver