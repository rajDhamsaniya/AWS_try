 YELLOW='\033[1;33m'
 RED='\033[1;31m'
 GREEN='\033[1;32m'
 BLUE='\033[1;34m'

 function okayGreen()
 {
     echo -e "${GREEN}-----> $*"
 }

 function acceptableYellow()
 {
     echo -e "${YELLOW}-----> $*"
 }
 
 function worstRed()
 {
     echo -e "${RED}-----> $*"
 }

 function infoBlue()
 {
     echo -e "${BLUE}-----> $*"
 }


 infoBlue "new term"