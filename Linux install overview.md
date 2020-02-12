# Swift 5.1/Vapor Install on Ubuntu 18.04

1. `eval "$(curl -sL https://apt.vapor.sh)"`
1. `apt update`
1. `apt upgrade -y`
1. `apt install git clang libicu-dev vapor`


1. `curl -O https://swift.org/builds/swift-5.1.3-release/ubuntu1804/swift-5.1.3-RELEASE/swift-5.1.3-RELEASE-ubuntu18.04.tar.gz`
1. `tar -xvf swift-5.1.3-RELEASE-ubuntu18.04.tar.gz` 
1. `mv swift-5.1.3-RELEASE-ubuntu18.04/ /usr/share/swift`
1. `echo "export PATH=/usr/share/swift/usr/bin:$PATH" >> ~/.bashrc`
1. `source .bashrc` 
1. `swift --version` # confirm 5.1 +

and then, obviously within the vapor project directory

1. `vapor update`
1. `vapor run --hostname=0.0.0.0 --port=80`


