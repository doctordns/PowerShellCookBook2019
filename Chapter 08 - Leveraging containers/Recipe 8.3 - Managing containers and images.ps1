# Recipe 8.2 - Managing containers and images  - LOG

# 1. prune anything that exists in docker land




PS C:\foo\> docker system prune -a
WARNING! This will remove:
        - all stopped containers
        - all networks not used by at least one container
        - all images without at least one container associated to them
        - all build cache