# Recipe 8.2 - Deploying a Hello World Application 
#
#  Run on CH1


# 1. Find Hello-work containers at the Docker Hub
docker search hello-world

# 2. Pull the Docker official hello-world image
docker pull hello-world

# 3. Check the Image just downloaded
docker image ls

# 4. Run the hello-world container image
docker run hello-world

# 5. Look for Microsoft images on the Docker Hub:
docker search microsoft

# 6. Get nano server base image
docker image pull mcr.microsoft.com/windows/nanoserver:1809 

# 7. Run the nanoserver base image:
docker run mcr.microsoft.com/windows/nanoserver:1809 

# 8. Check the images available now on CH1:
docker image ls

# 9. Inspect the first image:
$Images = docker image ls
$Rxs = '(\w+)  +(\w+)  +(\w+)  '
$OK = $Images[1] -Match $Rxs
$Image = $Matches[1]  # grab the image name
docker inspect $image | ConvertFrom-Json

# 10. Get another (older) image and try to run it:
docker image pull microsoft/nanoserver | Out-Null
docker run microsoft/nanoserver 

# 11. run it with isolation
docker run --isolation=hyperv microsoft/nanoserver 

# 12. look at differences in run times with hyper-V
# run with no isolation
$S1 = Get-Date
docker run hello-world |
    Out-Null
$E1 = Get-Date
$T1 = ($E1-$S1).TotalMilliseconds
# run with isolation
$S2 = Get-Date
docker run --isolation=hyperv hello-world | Out-Null
$E2 = get-date
$T2 = ($E2-$S2).TotalMilliseconds
"Without isolation, took : $T1 milliseconds"
"With isolation, took    : $T2 milliseconds"

# 13. run a detached container!
docker image pull microsoft/iis | out-null
docker run -d -p 80:80 microsoft/iis ping -t localhost |
  Out-Null
  
# 14. Use IIS:
Start-Process http://CH1.Reskit.Org
   
# 15. Is IIS loaded?IIS?
Get-Windowsfeature -Name Web-Server

# 16. check the container
docker container ls

# 17. And stop kill the contaienr
$CS = (docker container ls)[1] | 
        Where-Object {$_ -match '(  \w+$)'}
$CN = $Matches[0].trim()
docker container stop ($CN) | Out-Null

# 18. And remove all images
docker rmi $(docker images -q) -f | out-Null

# 19. and what's left?
docker image ls
docker container ls

